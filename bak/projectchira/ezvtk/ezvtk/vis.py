import vtk
import  Tkinter
from vtk.tk.vtkTkRenderWindowInteractor import vtkTkRenderWindowInteractor
from vtk.util.numpy_support import numpy_to_vtk

from contextlib import contextmanager
import shutil
import tempfile
import subprocess as sp

@contextmanager
def make_temp_path():
    path = tempfile.mkdtemp()
    yield path
    shutil.rmtree(path)

    
class vtkTkRenderWindowInteractorNoCharEvent(vtkTkRenderWindowInteractor):
    """ A subclass of vtkTkRenderWindowInteractor that doesn't generate a CharEvent

    Otherwise it seems impossible from Python to disable the default
    key bindings set up by vtkInteractorStyle.
    """
    def KeyPressEvent(self, event, ctrl, shift):
        key = chr(0)
        if event.keysym_num < 256:
            key = chr(event.keysym_num)
        self._Iren.SetEventInformationFlipY(event.x, event.y, ctrl,
                                            shift, key, 0, event.keysym)
        self._Iren.KeyPressEvent()
        # Don't generate the CharEvent
        # self._Iren.CharEvent()

class Viewer(object):

    def __init__(self, width=1400, height=1000, title='VTK Viewer'):
        
        self.renderer = vtk.vtkRenderer()
        self.renderer.SetBackground(1.0, 1.0, 1.0)
        
        self.render_window = vtk.vtkRenderWindow()
        self.render_window.AddRenderer(self.renderer)
        self.render_window.SetSize(width, height)

        self.root = Tkinter.Tk()
        self.root.title(title)
        self.render_window_interactor = vtkTkRenderWindowInteractorNoCharEvent(self.root, rw=self.render_window, width=width, height=height)
        self.render_window_interactor.Initialize()
        self.render_window_interactor.pack(fill='both', expand=1)

        self.cam_trackball = vtk.vtkInteractorStyleTrackballCamera()
        self.cam_trackball.SetCurrentRenderer(self.renderer)
        self.render_window_interactor.SetInteractorStyle(self.cam_trackball)
        self.cam_trackball.AddObserver('KeyPressEvent', self.on_key_press)
        self.key_callbacks = {}

        self.act_trackball = vtk.vtkInteractorStyleTrackballActor()
        self.act_trackball.SetCurrentRenderer(self.renderer)
        self.act_trackball.AddObserver('KeyPressEvent', self.on_key_press)
        self.act_trackball.AddObserver('InteractionEvent', self.on_actor_move)
        self.actor_move_callbacks = []

        self.mouse_pick_interactor = vtk.vtkInteractorStyleUser()
        self.mouse_pick_interactor.SetCurrentRenderer(self.renderer)
        self.mouse_pick_interactor.AddObserver('KeyPressEvent', self.on_key_press)
        self.mouse_pick_interactor.AddObserver('LeftButtonPressEvent', lambda x, y: self.pick(True))

        self.rubber_band_interactor = vtk.vtkInteractorStyleRubberBand3D()
        self.rubber_band_interactor.SetCurrentRenderer(self.renderer)
        self.rubber_band_interactor.AddObserver('KeyPressEvent', self.on_key_press)
        self.rubber_band_interactor.AddObserver('SelectionChangedEvent', self.on_box_select)
        self.box_select_callbacks = []

        # Create pickers
        self.cell_picker = vtk.vtkCellPicker()
        self.cell_picker.AddObserver("EndPickEvent", self.on_pick)
        self.point_picker = vtk.vtkPointPicker()
        self.point_picker.AddObserver("EndPickEvent", self.on_pick)
        self.pick_callbacks = []

    def on_key_press(self, obj, event):
        key = self.render_window_interactor.GetKeySym().lower()
        if key in self.key_callbacks:
            self.key_callbacks[key]()

    def on_pick(self, obj, event):
        for f in self.pick_callbacks:
            f(obj, event, self.pick_from_mouse)

    def on_actor_move(self, obj, event):
        for f in self.actor_move_callbacks:
            f(obj, event)

    def on_box_select(self, obj, event):
        for f in self.box_select_callbacks:
            f(obj.GetStartPosition(), obj.GetEndPosition())

    def render(self):
        self.render_window.Render()

    def add_troupes(self, *troupes):
        for troupe in troupes:
            for actor in troupe.actors:
                self.renderer.AddActor(actor)

    def remove_troupes(self, *troupes):
        for troupe in troupes:
            for actor in troupe.actors:
                self.renderer.RemoveActor(actor)

    def set_camera_position(self, position):
        camera = self.renderer.GetActiveCamera()
        camera.SetPosition(position)

    def set_camera_parallel_view_size(self, size):
        camera = self.renderer.GetActiveCamera()
        camera.ParallelProjectionOn()
        camera.SetParallelScale(size)
        
    def set_camera_up(self, up):
        camera = self.renderer.GetActiveCamera()
        camera.SetViewUp(up)

    def set_camera_focal_point(self, focal_point):
        camera = self.renderer.GetActiveCamera()
        camera.SetFocalPoint(focal_point)

    def add_key_callback(self, key, callback_function):
        self.key_callbacks[key] = callback_function
        
    def add_pick_callback(self, callback_function):
        self.pick_callbacks.append(callback_function)
        
    def add_actor_move_callback(self, callback_function):
        self.actor_move_callbacks.append(callback_function)

    def add_box_select_callback(self, callback_function):
        self.box_select_callbacks.append(callback_function)

    def box_select_mode(self):
        self.render_window_interactor.SetInteractorStyle(self.rubber_band_interactor)

    def move_actor_mode(self):
        self.render_window_interactor.SetInteractorStyle(self.act_trackball)

    def move_camera_mode(self):
        self.render_window_interactor.SetInteractorStyle(self.cam_trackball)

    def mouse_pick_mode(self):
        self.render_window_interactor.SetInteractorStyle(self.mouse_pick_interactor)

    def render_to_file(self, path):
        print 'render to', path
        filter = vtk.vtkWindowToImageFilter()
        filter.SetInput(self.render_window_interactor.GetRenderWindow())
        filter.SetMagnification(1)
        filter.SetInputBufferTypeToRGBA()
        filter.Update()
        
        png = vtk.vtkPNGWriter()
        png.SetFileName(path)
        png.SetInputConnection(filter.GetOutputPort())
        png.Write()

        self.render_window_interactor.GetRenderWindow().Render()

    def render_video(self, frame_generator, path=None, bitrate=20, defaultextension='avi', **kwargs):

        if path == None:
            import tkFileDialog
            file_dialog_options = {}
            for key in ["initialdir"]:
                if key in kwargs.keys():
                    file_dialog_options[key] = kwargs[key]
            file_dialog_options["filetypes"] = [('Video', '*.avi')]
            file_dialog_options["defaultextension"] = defaultextension
            path = tkFileDialog.asksaveasfilename(**file_dialog_options)
            if not path:
                return

        with make_temp_path() as tmp_path:

            print 'Will render images to', tmp_path, 'and then store video at', path

            for i_frame, _ in enumerate(frame_generator()):
                self.render()
                self.render_to_file(tmp_path + "/%05d.png" % i_frame)


            sp.call('ffmpeg -i %s -y -b:v %dM %s' % (tmp_path + '/%05d.png', bitrate, path))

    def pick(self, from_mouse):
        self.pick_from_mouse = from_mouse
        x, y = self.render_window_interactor._Iren.GetLastEventPosition()
        if from_mouse:
            self.point_picker.Pick(x, y, 0, self.renderer)
        else:
            self.cell_picker.Pick(x, y, 0, self.renderer)

    def start(self):
        self.render_window_interactor.Initialize()
        self.render_window_interactor.Start()
        self.renderer.ResetCameraClippingRange()
        self.root.mainloop()