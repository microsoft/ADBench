import math
import torch


# The LSTM model
def lstm(weight, bias, hidden, cell, _input):
    # NOTE this line came from: gates = hcat(input,hidden) * weight .+ bias
    gates = torch.cat((_input, hidden, _input, hidden)) * weight + bias
    hsize = hidden.shape[0]
    forget = torch.sigmoid(gates[0: hsize])
    ingate = torch.sigmoid(gates[hsize: 2 * hsize])
    outgate = torch.sigmoid(gates[2 * hsize: 3 * hsize])
    change = torch.tanh(gates[3 * hsize:])
    cell = cell * forget + ingate * change
    hidden = outgate * torch.tanh(cell)
    return (hidden, cell)


# Predict output given an input
def predict(w, w2, s, x):
    s2 = torch.tensor(s)
    # NOTE not sure if this should be element-wise or matrix multiplication
    x = x * w2[0]
    for i in range(0, len(s), 2):
        (s2[i], s2[i + 1]) = lstm(w[i], w[i + 1], s[i], s[i + 1], x)
        x = s2[i]
    return (x * w2[1] + w2[2], s2)


# Get the average loss for the LSTM across a sequence of inputs
def loss(main_params, extra_params, state, sequence, _range=None):
    if _range is None:
        _range = range(0, len(sequence) - 1)

    total = 0.0
    count = 0
    _input = sequence[_range[0]]
    all_states = [state]
    for t in _range:
        ypred, new_state = predict(main_params, extra_params, all_states[t], _input)
        all_states.append(new_state)
        ynorm = ypred - torch.log(sum(torch.exp(ypred), 2))
        ygold = sequence[t + 1]
        total += sum(ygold * ynorm)
        count += ygold.shape[0]
        _input = ygold
    return -total / count


# Read a text file to a matrix of one-hot character vectors
def read_data(fn):
    data_file = open(fn, encoding="utf8")
    full_text = data_file.read()
    data_file.close()

    bits = math.ceil(math.log2(max([ord(c) for c in full_text])))

    # Use only a portion of the text for testing
    use_text = full_text[:10000]

    return torch.tensor(list(map(lambda c: list(map(lambda b: float(b), bin(ord(c))[2:].zfill(bits))), use_text)))


# Hidden layer count constant
layer_count = 4

# Read data (using shakespeare as example text)
all_data = read_data("lstm-data.txt")

# Randomly generate past state, and parameters
state = torch.rand((2 * layer_count, all_data.shape[1]))
# NOTE not sure what the dimensions for the weights matrix should be
#   it didn't seem to be given anywhere in the blog post/code
#   but what I have now was all I could figure out to get it to work
#   see other NOTE comments (those are the lines which determined this choice)
main_params = torch.rand((2 * layer_count, all_data.shape[1] * 4), requires_grad=True)
extra_params = torch.rand((3, all_data.shape[1]), requires_grad=True)

# Run the loss function
loss_result = loss(main_params, extra_params, state, all_data)

# Autodiff
loss_result.backward()
grad = (main_params.grad, extra_params.grad)
