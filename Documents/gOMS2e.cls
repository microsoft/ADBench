%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% This is file `gOMS2e.cls'
%%
% Version: v5.0
%%
% gOMS - Optimization Methods & Software
%%
% This file is part of the LaTeX2e system.
%%
% Suitcase: CMR family
%%
% History of Changes:
% v1.0 - First released 1998/04/09
% v2.0 - First released 2004/07/01
% 1. Provision for subject classification after the Keywords using \classcode,
%    e.g. "AMS Subject Classification: F1.1; F4.3"
% v2.1 - First released 2006/07/22
% 1. Inclusion of \jvol{} \jnum{} \jyear{} \jmonth{} optional (defaults to 'Vol. 00, No. 00, Month 20XX')
% 2. Inclusion of \received optional (defaults to 'Received 00 Month 20XX; final version received 00 Month 20XX')
% 3. Upright lc Greek, etc. available
% 4. First page footnote available for gOMS articles
% v2.2 - First released 2006/11/08
% 1. Abstract, keywords and classcodes indented left and right
% v3.1 - First released 2007/10/30
% 1. Page width 32.65pc
% 2. Converted style to new Style 2 with Reference Style S
% 3. Provision for \articletype above \title (e.g. RESEARCH ARTICLE, EDITORIAL,
%    BOOK REVIEW, BRIEF COMMUNICATION); default is blank
% v3.2 - First released 2008/05/12
% 1. enumerate.sty added
% 2. BST modified to quote up to 10 authors' names in references list
% v3.3 - First released 2008/08/06
% 1. Removed call for mathbbol.sty so that openface characters now default to AMS fonts
% v3.4 - First released 2008/10/31
% 1. BST modified to quote all authors' names in references list, and
%    identical author lists are repeaeted instead of being replaced by three en-rules
% v3.5 - First released 2008/10/31
% 1. BST modified to make references to the numbers of algorithms, facts and examples
%    upright instead of italic, while leaving the headings "Algorithm 1", etc., all italic.
% v3.6 - First released 2009/05/14
% 1. Algorithm and remark numbering bug fixed
% v4.0 - First released 2013/08/19
% 1. Page width 35pc
% v4.1 - First released 2013/11/07
% 1. subfigure.sty no longer called by default
% 2. Footnote numbering adjusted to match journal style
% v4.2 - First released 2014/11/10
% 1. Incorporation of .eps artwork in sample PDF using epstopdf
% v5.0 - First released 2015/01/28
% 1. Updated and improved title commands
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gOMS2e}[2015/01/28 v5.0 Optimization Methods & Software LaTeX2e document class]

\def\jobtag{Optimization Methods \& Software}
\newif\ifappendix\appendixfalse
\newif\ifsuppldata

\DeclareOption{suppldata}{\suppldatatrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ExecuteOptions{a4paper,oneside,onecolumn,final}
\ProcessOptions

\LoadClass[11pt,a4paper]{article}

\RequirePackage{amsmath,amssymb,amsfonts,amsbsy,amsthm,epsfig,graphicx,rotating}
\RequirePackage[left=7.5pc,right=7.5pc,top=1in,bottom=1in]{geometry}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Boxes & Dimensions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\newdimen\draftrule
\newdimen\typeheight
\newdimen\typewidth
\setlength\textwidth{35pc}
\setlength\textheight{650pt}
\setlength\parindent{10pt}
\newbox\tempbox
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Boxes & Dimensions %%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fonts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\abstractfont{\normalfont\fontsize{9}{10}\selectfont\leftskip2pc\rightskip2pc}%
\def\articletypefont{\fontsize{13}{16}\selectfont\bfseries\centering\MakeUppercase}%
\def\authorfont{\normalfont\fontsize{10}{13}\selectfont\centering}%
\def\bibliofont{\fontsize{10}{12}\selectfont}%
\def\extractfont{\fontsize{10}{12}\selectfont\leftskip12pt\rightskip12pt}%
\def\figcaptionfont{\fontsize{8}{10}\selectfont}%
\def\fignumfont{\fontsize{8}{10}\selectfont}%
\def\keywordfont{\normalfont\fontsize{9}{10}\selectfont\leftskip2pc\rightskip2pc plus1fill}%
\def\listfont{}%
\def\receivedfont{\normalfont\fontsize{8}{12}\selectfont\centering\itshape}%
\def\rhfont{\fontsize{8}{12}\selectfont\itshape}%
\def\rffont{\fontsize{8}{10}\selectfont\itshape}%
\def\sectionfont{\fontsize{11}{13}\selectfont\bfseries\raggedright\boldmath}%
\def\subsectionfont{\fontsize{11}{13}\selectfont\bfseries\itshape\raggedright\boldmath}%
\def\subsubsectionfont{\fontsize{11}{13}\selectfont\itshape\raggedright}%
\def\paragraphfont{\fontsize{11}{13}{\selectfont\itshape}}%
\def\subparagraphfont{\fontsize{11}{13}\selectfont\itshape}%
\def\tablefont{\fontsize{8}{9}\selectfont}%
\def\tablecaptionfont{\fontsize{8}{10}\selectfont\leftskip\tabledim\rightskip\tabledim}%
\def\tablenumfont{\fontsize{8}{10}\selectfont}%
\def\tabnotefont{\fontsize{8}{9}\selectfont}%
\def\titlefont{\fontsize{13}{16}\selectfont\bfseries\centering}%
\def\thanksfont{\fontsize{8}{10}\selectfont}%
%
\def\@xpt{10}
\def\@xipt{11}
\def\@xiiipt{13}
\def\@xivpt{14}
\def\@xvipt{16}
\def\@xviiipt{18}
%
\renewcommand\normalsize{%
   \@setfontsize\normalsize\@xipt\@xiiipt
   \abovedisplayskip 13\p@ \@plus2\p@ minus.5pt
   \abovedisplayshortskip \abovedisplayskip
   \belowdisplayskip 13\p@ \@plus2\p@ minus.5pt
   \belowdisplayshortskip\belowdisplayskip
   \let\@listi\@listI}
%
\renewcommand\small{%
   \@setfontsize\small\@xpt{11}%
   \abovedisplayskip 8.5\p@ \@plus3\p@
   \abovedisplayshortskip \z@ \@plus2\p@
   \belowdisplayshortskip 4\p@ \@plus2\p@
   \def\@list1{\leftmargin\leftmargin1
               \topsep 6\p@ \@plus2\p@
               \parsep 2\p@ \@plus\p@
               \itemsep \parsep}%
   \belowdisplayskip \abovedisplayskip\setSmallDelims}
%
\def\setSmallDelims{%
\def\big##1{{\hbox{$\left##1\vbox to7.5\p@{}\right.\n@space$}}}%
\def\Big##1{{\hbox{$\left##1\vbox to10.5\p@{}\right.\n@space$}}}%
\def\bigg##1{{\hbox{$\left##1\vbox to13.5\p@{}\right.\n@space$}}}%
\def\Bigg##1{{\hbox{$\left##1\vbox to16.5\p@{}\right.\n@space$}}}%
\def\biggg##1{{\hbox{$\left##1\vbox to19.5\p@{}\right.\n@space$}}}%
\def\Biggg##1{{\hbox{$\left##1\vbox to22.5\p@{}\right.\n@space$}}}%
}
%
\renewcommand\footnotesize{%
   \@setfontsize\footnotesize\@viiipt{10}%
   \abovedisplayskip 6\p@ \@plus2\p@
   \abovedisplayshortskip \z@ \@plus\p@
   \belowdisplayshortskip 3\p@ \@plus\p@
   \def\@listi{\leftmargin\leftmargini
               \topsep 6\p@ \@plus\p@
               \parsep 2\p@ \@plus\p@
               \itemsep \parsep}%
   \belowdisplayskip \abovedisplayskip\setFootnotesizeDelims
   }
%
\def\setFootnotesizeDelims{%
\def\big##1{{\hbox{$\left##1\vbox to6.5\p@{}\right.\n@space$}}}%
\def\Big##1{{\hbox{$\left##1\vbox to9.5\p@{}\right.\n@space$}}}%
\def\bigg##1{{\hbox{$\left##1\vbox to12.5\p@{}\right.\n@space$}}}%
\def\Bigg##1{{\hbox{$\left##1\vbox to15.5\p@{}\right.\n@space$}}}%
\def\biggg##1{{\hbox{$\left##1\vbox to18.5\p@{}\right.\n@space$}}}%
\def\Biggg##1{{\hbox{$\left##1\vbox to21.5\p@{}\right.\n@space$}}}%
}
%
\def\capsdefault{caps}% All CAPS
\DeclareRobustCommand\capsshape
        {\not@math@alphabet\capsshape\mathrm
         \fontshape\capsdefault\selectfont}
%
\DeclareOldFontCommand{\bi}{\bfseries\itshape}{\bfseries\itshape}
\renewcommand{\cal}{\protect\pcal}%
\newcommand{\pcal}{\@fontswitch{\relax}{\mathcal}}
\renewcommand{\mit}{\protect\pmit}%
\newcommand{\pmit}{\@fontswitch{\relax}{\mathnormal}}
%
\renewcommand\rmdefault{cmr}
\newcommand\rmmathdefault{cmr}
%
\DeclareFontFamily{OT1}{Clearface}{}
\DeclareFontShape{OT1}{Clearface}{m}{n}{ <-> Clearface-Regular }{}
\DeclareFontShape{OT1}{Clearface}{m}{it}{ <-> Clearface-RegularItalic }{}
\def\encodingdefault{OT1}%
\fontencoding{OT1}%
%
\def\boldmath{\mathversion{bold}}
\def\bm#1{\mathchoice
          {\mbox{\boldmath$\displaystyle#1$}}%
          {\mbox{\boldmath$#1$}}%
          {\mbox{\boldmath$\scriptstyle#1$}}%
          {\mbox{\boldmath$\scriptscriptstyle#1$}}}
%
% Macro for changing \mathversion's
\providecommand{\mathch}[2]{% Derived from AMSBSY.STY
  \begingroup
  \let\@nomath\@gobble \mathversion{#1}%
  \math@atom{#2}{%
  \mathchoice%
    {\hbox{$\m@th\displaystyle#2$}}%
    {\hbox{$\m@th\textstyle#2$}}%
    {\hbox{$\m@th\scriptstyle#2$}}%
    {\hbox{$\m@th\scriptscriptstyle#2$}}}%
  \endgroup}
%
% The following changes encoding from U to OML
% This allows to use eurm/b as (more or less) a math italic font.
%
\DeclareFontFamily{OML}{eur}{\skewchar\font'177}
\DeclareFontShape{OML}{eur}{m}{n}{
  <5> <6> <7> <8> <9> gen * eurm
  <10> <10.95> <12> <14.4> <17.28> <20.74> <24.88> eurm10
  }{}
\DeclareFontShape{OML}{eur}{b}{n}{
  <5> <6> <7> <8> <9> gen * eurb
  <10> <10.95> <12> <14.4> <17.28> <20.74> <24.88> eurb10
  }{}
%
\DeclareMathVersion{upright}
\DeclareMathVersion{boldupright}
\SetSymbolFont{letters}{upright}    {OML}{eur}{m}{n}
\SetSymbolFont{letters}{boldupright}{OML}{eur}{b}{n}
\DeclareRobustCommand{\mathup}[1]{\mathch{upright}{#1}}
\DeclareRobustCommand{\mathbup}[1]{\mathch{boldupright}{#1}}
%
\newcommand\ualpha{\mathup{\alpha}}
\newcommand\ubeta{\mathup{\beta}}
\newcommand\ugamma{\mathup{\gamma}}
\newcommand\udelta{\mathup{\delta}}
\newcommand\uepsilon{\mathup{\epsilon}}
\newcommand\uzeta{\mathup{\zeta}}
\newcommand\ueta{\mathup{\eta}}
\newcommand\utheta{\mathup{\theta}}
\newcommand\uiota{\mathup{\iota}}
\newcommand\ukappa{\mathup{\kappa}}
\newcommand\ulambda{\mathup{\lambda}}
\newcommand\umu{\mathup{\mu}}
\newcommand\unu{\mathup{\nu}}
\newcommand\uxi{\mathup{\xi}}
\newcommand\upi{\mathup{\pi}}
\newcommand\urho{\mathup{\rho}}
\newcommand\usigma{\mathup{\sigma}}
\newcommand\utau{\mathup{\tau}}
\newcommand\uupsilon{\mathup{\upsilon}}
\newcommand\uphi{\mathup{\phi}}
\newcommand\uchi{\mathup{\chi}}
\newcommand\upsi{\mathup{\psi}}
\newcommand\uomega{\mathup{\omega}}
\newcommand\uvarepsilon{\mathup{\varepsilon}}
\newcommand\uvartheta{\mathup{\vartheta}}
\newcommand\uvarpi{\mathup{\varpi}}
\let\uvarrho\varrho % don't exist in eurm.
\let\uvarsigma\varsigma
\newcommand\uvarphi{\mathup{\varphi}}
\newcommand\ubalpha{\mathbup{\alpha}}
\newcommand\ubbeta{\mathbup{\beta}}
\newcommand\ubgamma{\mathbup{\gamma}}
\newcommand\ubdelta{\mathbup{\delta}}
\newcommand\ubepsilon{\mathbup{\epsilon}}
\newcommand\ubzeta{\mathbup{\zeta}}
\newcommand\uboldeta{\mathbup{\eta}}
\newcommand\ubtheta{\mathbup{\theta}}
\newcommand\ubiota{\mathbup{\iota}}
\newcommand\ubkappa{\mathbup{\kappa}}
\newcommand\ublambda{\mathbup{\lambda}}
\newcommand\ubmu{\mathbup{\mu}}
\newcommand\ubnu{\mathbup{\nu}}
\newcommand\ubxi{\mathbup{\xi}}
\newcommand\ubpi{\mathbup{\pi}}
\newcommand\ubrho{\mathbup{\rho}}
\newcommand\ubsigma{\mathbup{\sigma}}
\newcommand\ubtau{\mathbup{\tau}}
\newcommand\ubupsilon{\mathbup{\upsilon}}
\newcommand\ubphi{\mathbup{\phi}}
\newcommand\ubchi{\mathbup{\chi}}
\newcommand\ubpsi{\mathbup{\psi}}
\newcommand\ubomega{\mathbup{\omega}}
\newcommand\ubvarepsilon{\mathbup{\varepsilon}}
\newcommand\ubvartheta{\mathbup{\vartheta}}
\newcommand\ubvarpi{\mathbup{\varpi}}
\newcommand\ubvarrho{\boldsymbol{\varrho}} % don't exist in eurb.
\newcommand\ubvarsigma{\boldsymbol{\varsigma}}
\newcommand\ubvarphi{\mathbup{\varphi}}
\newcommand\upartial {\mathup{\partial}}
\newcommand\ubpartial{\mathbup{\partial}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Fonts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Title commands %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\articletype#1{\gdef\@articletype{{#1}}\MakeUppercase}
\def\title#1{\gdef\@title{{#1}}}
\def\author#1{\def\and{and }\gdef\@author{#1}}
\def\received#1{\gdef\@received{#1}}
\gdef\@received{Received 00 Month 20XX; final version received 00 Month 20XX}
%
\long\def\name#1{#1\\\vspace{6pt}}%
\long\def\affil#1{\textit{#1}\\}
\long\def\email#1{#1\\}
%
\def\thanks#1{\begingroup
\def\protect{\noexpand\protect\noexpand}\xdef\@thanks{\@thanks%
  \protect\footnotetext[\the\c@footnote]{\thanksfont#1}}\endgroup}
%
\renewcommand\maketitle{\par%
        \renewcommand\thefootnote{}%
  \begingroup
    \@maketitle%
    \thispagestyle{title}
  \endgroup
  \@thanks
  \let\@maketitle\relax
  \gdef\@thanks{}\gdef\@author{}\gdef\@title{}\gdef\@articletype{}%
        \renewcommand\thefootnote{\arabic{footnote}}%
  \@afterheading}
%
\def\@maketitle{\thispagestyle{plain}
  \clearpage
  \null
  \bgroup
    \parindent0pt
    \vspace*{48pt}
    {\articletypefont{\@articletype}\par}%
    \vskip13pt
    {\titlefont{\@title}\par}%
    \vskip13pt
    {\authorfont\@author\par}%
    \ifsuppldata\else
    \vskip6pt
    {\receivedfont{\rm(}\@received{\rm)}\par}%
    \fi
    \vskip17pt
  \egroup}
%
\renewenvironment{abstract}{%
        \abstractfont
  \noindent\ignorespaces}{%
        \par}\addvspace{32pt}
%
\newenvironment{keywords}{\global\keywordstrue%
        \par\addvspace{11pt}%
  \keywordfont
  \noindent{{\bf{Keywords:}} }\ignorespaces
}{%
        \par\addvspace{26pt plus 4pt}\@afterheading}
%
\newif\ifkeywords
\newenvironment{classcode}{%
        \par\ifkeywords\addvspace{-20pt}\else\addvspace{11pt}\fi%
  \keywordfont
  \noindent{\it AMS Subject Classification{\rm{:}}\ }\ignorespaces
}{%
        \par\addvspace{26pt plus 4pt}\@afterheading}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Title commands %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Sectioning commands %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\setcounter{secnumdepth}{4}
%\newcounter {part}
%\newcounter {section}
%\newcounter {subsection}[section]
%\newcounter {subsubsection}[subsection]
%\newcounter {paragraph}[subsubsection]
%\newcounter {subparagraph}[paragraph]
\renewcommand\thepart       {\arabic{part}}
\renewcommand\thesection       {\arabic{section}}
\renewcommand\thesubsection    {\thesection.\arabic{subsection}}
\renewcommand\thesubsubsection {\thesubsection.\arabic{subsubsection}}
\renewcommand\theparagraph     {\thesubsubsection.\arabic{paragraph}}
\renewcommand\thesubparagraph  {\theparagraph.\arabic{subparagraph}}
%
\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-26pt \@plus-4pt \@minus-2pt}%
                                   {13pt}%
                                   {\sectionfont}}%
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-24pt \@plus-3pt \@minus-2pt}%
                                     {7pt}%
                                     {\subsectionfont}}%
\renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                                     {18pt \@plus2pt \@minus2pt}%
                                     {6pt}%
                                     {\subsubsectionfont}}%
\renewcommand\paragraph{\@startsection{paragraph}{4}{\z@}%
                                     {18pt \@plus1pt \@minus1pt}%
                                     {-6pt}%
                                     {\paragraphfont}}%
\renewcommand\subparagraph{\@startsection{subparagraph}{5}{\parindent}%
                                      {3.25ex \@plus1ex}%
                                      {-1em}%
                                      {\reset@font\normalsize}}%
%
\def\@startsection#1#2#3#4#5#6{%
  \if@noskipsec \leavevmode \fi
  \par
  \@tempskipa #4\relax
  \ifdim \@tempskipa <\z@
    \@tempskipa -\@tempskipa \@afterindentfalse
  \fi
  \if@nobreak
    \ifnum#2=3
      \vskip4pt
    \fi
    \everypar{}%
  \else
    \addpenalty\@secpenalty\addvspace\@tempskipa
  \fi
  \@ifstar
    {\@ssect{#3}{#4}{#5}{#6}}%
    {\@dblarg{\@sect{#1}{#2}{#3}{#4}{#5}{#6}}}}
%
\renewcommand\appendixname{Appendix}
\def\@sseccntformat#1{\csname the#1\endcsname\quad}
\def\@appseccntformat#1{\appendixname\ \csname the#1\endcsname.\ }
\def\@seccntformat#1{\csname the#1\endcsname.\quad}
\def\@sect#1#2#3#4#5#6[#7]#8{\ifnum #2>\c@secnumdepth
     \let\@svsec\@empty\else
     \refstepcounter{#1}%
     \let\@@protect\protect
     \def\protect{\noexpand\protect\noexpand}%
     \ifnum#2>\@ne\edef\@svsec{\@sseccntformat{#1}}\else\edef\@svsec{\@seccntformat{#1}}\fi%
     \let\protect\@@protect\fi
     \@tempskipa #5\relax
      \ifdim \@tempskipa>\z@
        \begingroup #6\relax
          \ifnum#2=1
               \@hangfrom{\hskip #3\relax\@svsec}%
                         {\interlinepenalty \@M {#8}\par}%
          \else
                \ifnum#2=2
                    \@hangfrom{\hskip #3\relax{\em\@svsec}}%
                             {\interlinepenalty \@M #8\par}%
                \else
                        \@hangfrom{\hskip #3\relax\@svsec}%
                             {\interlinepenalty \@M #8\par}%
                \fi
         \fi
        \endgroup
            \csname #1mark\endcsname{#7}
        \addcontentsline
         {toc}{#1}{\ifnum #2>\c@secnumdepth \else
                      \protect\numberline{\csname the#1\endcsname}\fi
                    #7}%
       \else%
        \def\@svsechd{#6\hskip #3\relax
                   \em\@svsec #8.\csname #1mark\endcsname
                      {#7}\addcontentsline
                           {toc}{#1}{\ifnum #2>\c@secnumdepth \else
                           \protect\numberline{\csname the#1\endcsname}%
                                     \fi
                       #7}}\fi
     \@xsect{#5}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%% End Sectioning commands %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Floats %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\setcounter{topnumber}{4}
\renewcommand\topfraction{.9}
\setcounter{bottomnumber}{4}
\renewcommand\bottomfraction{.9}
\setcounter{totalnumber}{8}
\renewcommand\textfraction{.1}
\renewcommand\floatpagefraction{.91}
\setcounter{dbltopnumber}{5}
\renewcommand\dbltopfraction{.9}
\renewcommand\dblfloatpagefraction{.9}
%
\setlength\abovecaptionskip{7\p@}
\setlength\belowcaptionskip{\z@}
%
\def\FigName{figure}%
%
\long\def\@caption#1[#2]#3{\par\begingroup
    \@parboxrestore
    \normalsize
    \@makecaption{\csname fnum@#1\endcsname}{\ignorespaces #3}\par
  \endgroup}
%
\long\def\@makecaption#1#2{%
  \ifx\FigName\@captype
    \vskip5pt
    \setbox\tempbox\hbox{\figcaptionfont{\fignumfont#1}\hskip4pt#2}%
    \ifdim\wd\tempbox>\hsize
            {\figcaptionfont\noindent{\fignumfont#1}\hskip7pt\ignorespaces#2\par}
    \else
            \centerline{\box\tempbox}
    \fi
 \else
    {\tablecaptionfont
    {\tablenumfont#1}\hskip7pt\ignorespaces{#2}\par}%
   \vskip\belowcaptionskip
 \fi}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\renewcommand\thefigure{\@arabic\c@figure}
\def\fps@figure{tbp}
\def\ftype@figure{1}
\def\ext@figure{lof}
\def\fnum@figure{Figure~\thefigure.}%
\renewenvironment{figure}%
               {\figcaptionfont\@float{figure}}
               {\end@float}
\renewenvironment{figure*}%
               {\figcaptionfont\@dblfloat{figure}}
               {\end@dblfloat}

\def\ArtDir{art/}%
\def\ArtPiece{\@ifnextchar[{\@ArtPiece}{\@ArtPiece[]}}%
\def\@ArtPiece[#1]#2{\def\@tempa{#1}%
                     \hbox{\ifx\@tempa\@empty\else\epsfscale#1\fi
                     \noindent{\epsfbox{\ArtDir#2}}}}%
%
\newdimen\figheight
\newdimen\figwidth
%
\let\figformat\centerline
%
\def\figurebox#1#2#3#4{%
  \global\figheight#1\global\figwidth#2
  \def\@tempa{#4}%
  \leavevmode
  \ifx\@tempa\empty
    \figformat{\figbox}%
  \else
    \figformat{\ArtPiece[#3]{#4}}%
  \fi\par}
%
\def\figbox{\hbox{\vbox{\hsize\figwidth
            \hrule
            \hbox to\figwidth{\vrule\hss
            \vbox to \figheight{\vfill}%
            \vrule}\hrule}}}%
%
\def\figformat#1{\centerline{\footnotesize#1}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Figures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Tables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\renewcommand\thetable{\@arabic\c@table}
\def\fps@table{tbp}
\def\ftype@table{2}
\def\ext@table{lot}
\def\fnum@table{Table~\thetable.}%
\renewenvironment{table}%
               {\@float{table}}
               {\vskip5pt\end@float}
\renewenvironment{table*}%
               {\@dblfloat{table}}
               {\end@dblfloat}
%
\newdimen\tabledim
%
\long\def\tbl#1#2{%
 \setbox\tempbox\hbox{\tablefont #2}%
 \tabledim\hsize\advance\tabledim by -\wd\tempbox
    \global\divide\tabledim\tw@
 \caption{#1}
    \centerline{\box\tempbox}
  }%
%
\newenvironment{tabnote}{%
\par\vskip5pt\tabnotefont
\@ifnextchar[{\@tabnote}{\@tabnote[]}}{%
\par\vskip-5pt}
\def\@tabnote[#1]{\def\@Tempa{#1}\leftskip\tabledim\rightskip\leftskip%\hspace*{9pt}%
\ifx\@Tempa\@empty\else{\itshape #1:}\ \fi\ignorespaces}
%
\def\Hline{%
  \noalign{\ifnum0=`}\fi\hrule \@height 2\arrayrulewidth \futurelet
   \@tempa\@xhline}
%
\def\x{@{\extracolsep{\fill}}}
\def\toprule{\\[-5.5pt]\Hline\\[-3.5pt]}
\def\colrule{\\[-7.5pt]\hline\\[-5pt]}
\def\botrule{\\[-7.7pt]\Hline}
\def\crule#1{\\[-9.5pt]#1\\[-2.5pt]}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Tables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lists %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\newdimen\LabelSep
\LabelSep.5em
\newskip\TopSep
\TopSep 6\p@ %\@plus2\p@% \@minus1\p@
%
\def\@listI{\leftmargin\leftmargini
            \listparindent\parindent
            \parsep \z@\labelsep\LabelSep
            \topsep\TopSep
            \itemsep0\p@}
%
\let\@listi\@listI
\@listi
%
\def\@listii {\leftmargin\leftmarginii
              \labelwidth\leftmarginii
                    \listparindent\parindent
                    \parsep \z@\labelsep\LabelSep
              \topsep 0pt%6\p@ \@plus2\p@ \@minus1\p@
              \parsep\z@\itemsep\z@}
\def\@listiii{\leftmargin\leftmarginiii
                    \listparindent\parindent
              \labelwidth\leftmarginiii
              \topsep    0pt
              \parsep    \z@
              \partopsep0pt
              \itemsep0pt}
\def\@listiv {\leftmargin\leftmarginiv
              \labelwidth\leftmarginiv
              \advance\labelwidth-\labelsep}
\def\@listv  {\leftmargin\leftmarginv
              \labelwidth\leftmarginv
              \advance\labelwidth-\labelsep}
\def\@listvi {\leftmargin\leftmarginvi
              \labelwidth\leftmarginvi
              \advance\labelwidth-\labelsep}
%
\setlength\leftmargini{3pc}
\setlength\leftmarginii{2.2em}
\setlength\leftmarginiii{1.87em}
\setlength\leftmarginiv{1.7em}
\setlength\leftmarginv{1em}
\setlength\leftmarginvi{1em}
\setlength\leftmargin{\leftmargini}
\setlength\listparindent{\parindent}
\setlength\labelwidth{\leftmargini}
\addtolength\labelwidth{-\labelsep}
\renewcommand\theenumi{(\arabic{enumi})}
\renewcommand\theenumii{(\alph{enumii}}
\renewcommand\theenumiii{(\roman{enumiii}}
\renewcommand\theenumiv{(\Alph{enumiv}}
\renewcommand\labelenumi{\theenumi}
\renewcommand\labelenumii{\theenumii)}
\renewcommand\labelenumiii{\theenumiii)}
\renewcommand\labelenumiv{\theenumiv)}
\renewcommand\p@enumii{\theenumi}
\renewcommand\p@enumiii{\theenumi(\theenumii)}
\renewcommand\p@enumiv{\p@enumiii\theenumiii}
\renewcommand\labelitemi{$\m@th\bullet$}
\renewcommand\labelitemii{$\m@th\circ$}
\renewcommand\labelitemiii{\normalfont\textendash}
\renewcommand\labelitemiv{$\m@th\ast$}
%
\newbox\enumbox
\newdimen\enumwd
\def\enummax#1{\setbox\enumbox=\hbox{#1\hskip\labelsep}%
  \expandafter\global\csname leftmargin\romannumeral\the\@enumdepth\endcsname\wd\enumbox
}
%
\def\enumerate{\@ifnextchar[{\@enumerate}%
                                        {\@enumerate[\csname label\@enumctr\endcsname]}}
%
\def\@enumerate[#1]{\listfont\ifnum \@enumdepth >3 \@toodeep\else
      \advance\@enumdepth \@ne\edef\@enumctr{enum\romannumeral\the\@enumdepth}%
      \setcounter{\@enumctr}{1}\enummax{#1}\list
      {\csname label\@enumctr\endcsname}{\usecounter
        {\@enumctr}\def\makelabel##1{\hss\llap{##1}}}\fi}
%
\let\Item\item
\newenvironment{enumeroman}{%
  \def\theenumi{\roman{enumi}}\def\theenumii{\roman{enumii}}%
  \def\labelenumi{(\theenumi)}\def\labelenumii{(\theenumii)}%
        \let\item\Item
  \begin{enumerate}%
}{%
  \end{enumerate}}
%
\newenvironment{sequence}{%
  \def\theenumi{\alph{enumi}}\def\theenumii{\alph{enumii}}%
  \def\labelenumi{(\theenumi)}\def\labelenumii{(\theenumii)}%
        \let\item\Item
  \begin{enumerate}%
}{%
  \end{enumerate}}
%
\newdimen\unnummargin
\unnummargin12pt
%
\newenvironment{unnumlist}{%
        \let\item\Item
      \advance\@enumdepth \@ne
      \list{}{\leftmargin\unnummargin\itemindent-12pt\topsep6pt plus2pt
              \def\makelabel##1{\hss\llap{##1}}}%
}{%
  \endlist\advance\@enumdepth \m@ne}
%
\def\Itemize{%
  \ifnum \@itemdepth >3 \@toodeep\else \advance\@itemdepth \@ne
  \edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
  \list{\csname\@itemitem\endcsname}%
       {\ifnum \@itemdepth>1\topsep0pt\fi\leftmargin22.5pt\rightmargin1pc\labelsep6pt\def
                                                           \makelabel##1{\hss\llap{##1}}}\fi}
%
\def\endItemize{\endlist}
%
\renewenvironment{description}
               {\list{}{\labelwidth\z@ \itemindent-\leftmargin
                        \let\makelabel\descriptionlabel}}
               {\endlist}
\renewcommand*\descriptionlabel[1]{\hspace\labelsep
                                \normalfont\bfseries #1}
%
\renewenvironment{quote}{%
        \par\addvspace{13pt plus2pt minus1pt}
  \extractfont\noindent\ignorespaces
}{%
        \par\addvspace{13pt plus2pt minus1pt}
  \@endparenv}
%
\renewenvironment{quote}{%
        \par\addvspace{6pt}\let\itemize\Itemize\let\enditemize\endItemize
  \extractfont\noindent\ignorespaces
}{%
        \par\addvspace{6pt}
  \@endparenv}
%
\let\extract\quote
\let\endextract\endquote
%
\def\itemize{%
  \ifnum \@itemdepth >3 \@toodeep\else \advance\@itemdepth \@ne
  \edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
  \list{\csname\@itemitem\endcsname}%
       {\ifnum \@itemdepth>1\topsep0pt\fi\leftmargin11pt\labelsep6pt\def\makelabel##1{\hss\llap{##1}}}\fi}
%
\def\enditemize{\endlist}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Lists %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\appendices{\appendix\global\appendixtrue}
\renewcommand{\appendix}{%
   \global\appendixtrue
   \let\@seccntformat\@appseccntformat
   \setcounter{equation}{0}\renewcommand\theequation{\thesection\arabic{equation}}%
   \setcounter{section}{0}\renewcommand\thesection       {\Alph{section}}%
   \setcounter{subsection}{0}\renewcommand\thesubsection       {\thesection.\arabic{subsection}}%
   \setcounter{table}{0}\renewcommand\thetable{\thesection\@arabic\c@table}%
   \setcounter{figure}{0}\renewcommand\thefigure{\thesection\@arabic\c@figure}%
   \@addtoreset{equation}{section}
   \@addtoreset{table}{section}
   \@addtoreset{figure}{section}
}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Footnotes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\renewcommand\footnoterule{\kern2pt\hrule width 15pc height.25pt\kern4pt}%
\renewcommand\thefootnote{\fnsymbol{footnote}}
%
\def\@makefnmark{\hbox{$^{\@thefnmark}\m@th$}}%
\long\def\@makefntext#1{%
    \@makefnmark\ignorespaces#1\par}%
%
\long\def\@makefntext#1{\parindent0pt%
    \leavevmode\@makefnmark\ignorespaces#1\par}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Footnotes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Bibliography %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\usepackage[numbers,sort&compress]{natbib}
\let\bibfont\relax
\def\bibfont{\fontsize{9}{11}\selectfont}
\bibpunct[, ]{[}{]}{,}{n}{,}{,}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Bibliography %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Page styles %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\endpage#1{\gdef\@endpage{#1}}
\endpage{}%
\def\jname#1{\gdef\@jname{#1}}
\jname{Optimization Methods \& Software}
\def\jvol#1{\gdef\@jvol{#1}}
\gdef\@jvol{00}
\def\articletype#1{\gdef\@articletype{#1}}
\gdef\@articletype{\ }
\def\jnum#1{\gdef\@jnum{#1}}
\gdef\@jnum{00}
\def\jmonth#1{\gdef\@jmonth{#1}}
\gdef\@jmonth{Month}
\def\jyear#1{\gdef\@jyear{#1}}
\gdef\@jyear{20XX}
\def\doi#1{\gdef\@doi{#1}}
\gdef\@doi{}
%
\def\ps@headings{%
    \let\@oddfoot\@empty
    \def\@oddhead{{\slshape\rightmark}\hfil\thepage}%
    \let\@mkboth\markboth
    \def\sectionmark##1{%
      \markright {\MakeUppercase{%
        \ifnum \c@secnumdepth >\m@ne
          \thesection\quad
        \fi
        ##1}}}}
\def\ps@myheadings{%
    \let\@oddfoot\@empty\let\@evenfoot\@empty
    \def\@evenhead{\thepage\hfil\slshape\leftmark}%
    \def\@oddhead{{\slshape\rightmark}\hfil\thepage}%
    \let\@mkboth\@gobbletwo
    \let\sectionmark\@gobble
    \let\subsectionmark\@gobble
    }
\def\ps@title{%
    \let\@oddfoot\@empty
    \let\@evenfoot\@empty
    \def\@evenhead{}%
    \def\@oddhead{\hbox to \textwidth{{\small\begin{tabular}[t]{@{}l@{}}
                 \\%
    \ifsuppldata\else
                 {To appear in \itshape \@jname} \\Vol. \@jvol, No. \@jnum,
                 \ifx\@jmonth\empty\else\@jmonth\ \fi\@jyear, \thepage--\@endpage\\
                 \@doi\\
    \fi
                 \end{tabular}}%
                 \hfill%
                 }}%
    \let\@mkboth\@gobbletwo
    \let\sectionmark\@gobble
    \let\subsectionmark\@gobble
    }
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Page styles %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trimmarks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\ifsuppldata
\def\draftnote{}
\else
\def\draftnote{{\footnotesize\today\qquad\jobtag\qquad\jobname}\hfill}%
\fi
\def\floatqtoa#1{\vbox to 0pt{\vskip-20pt%\hskip\textwidth
\llap{\vbox{\hsize6pc\bf \footnotesize\raggedright#1}}}\vskip-12pt}%
\def\Qauthor#1{\marginpar{\footnotesize\bf\raggedright #1}}
\let\qtoa\Qauthor
%
\newdimen\drafttextwidth
\drafttextwidth\textwidth
%
\setlength\typeheight\textheight
\advance\typeheight\headheight
\advance\typeheight\headsep
%
\setlength\typewidth{\textwidth}
\global\newdimen \trimrule
 \trimrule.1pt
%
\def\trimmarks{%
  \vbox to 0pt{\vskip-70pt\hskip-70pt
  \draftnote\offinterlineskip
  \parindent0pt
  \leftskip0pt\rightskip0pt}%
%  \ifdraft
%    \vbox to 0pt{\hsize\trimwidth\offinterlineskip
%    \parindent0pt\leftskip0pt\rightskip0pt
%    \vbox to \trimheight{\offinterlineskip\parindent0pt
%    \hbox to \trimwidth{\vbox to 2pc{\vskip-3pc\hbox{\vrule height2pc width\trimrule}}\raisebox{2pc}{\hbox{\hskip-3pc\vrule width2pc height\trimrule}}\hfill
%      \raisebox{2pc}{\vrule width2pc height\trimrule\hskip-3.25pc}
%      \vbox to 2pc{\vskip-3pc\hbox{\vrule height2pc width\trimrule}}%
%    }\vfill
%    \hbox to \trimwidth{\hbox{\hskip-3pc\vrule height\trimrule width2pc}\vbox to 3pc{\vspace*{4pc}\hbox{\hskip1pc\vrule width\trimrule height2pc}}\hfill
%    \vbox to 3pc{\vskip4pc\hbox{\vrule height2pc width\trimrule}}\rlap{\hskip1pc\vrule width2pc height\trimrule}}}}%
%  \else
%   \trimrule.0pt
%    \vbox to 0pt{\hsize\trimwidth\offinterlineskip
%    \parindent0pt\leftskip0pt\rightskip0pt
%    \vbox to \trimheight{\offinterlineskip\parindent0pt
%    \hbox to \trimwidth{\vbox to 2pc{\vskip-3pc\hbox{\vrule height2pc width\trimrule}}\raisebox{2pc}{\hbox{\hskip-3pc\vrule width2pc height\trimrule}}\hfill
%      \raisebox{2pc}{\vrule width2pc height\trimrule\hskip-3.25pc}
%      \vbox to 2pc{\vskip-3pc\hbox{\vrule height2pc width\trimrule}}%
%    }\vfill
%    \hbox to \trimwidth{\hbox{\hskip-3pc\vrule height\trimrule width2pc}\vbox to 3pc{\vspace*{4pc}\hbox{\hskip1pc\vrule width\trimrule height2pc}}\hfill
%    \vbox to 3pc{\vskip4pc\hbox{\vrule height2pc width\trimrule}}\rlap{\hskip1pc\vrule width2pc height\trimrule}}}}%
%  \fi
%
\insidedraftrules}
%
\def\insidedraftrules{%
\vbox to 0pt{%
  \offinterlineskip\parindent0pt
  \vskip \topmargin
  \@tempdima\typeheight
  \moveright\@themargin
      \ifodd\c@page
         \vbox to\@tempdima{\hrule height\draftrule
         \vbox to 0pt{\vskip\headheight\vskip\headsep%\vskip-6pt
                      \noindent\hbox{\vrule height\draftrule width\textwidth}}%26pc
         \hbox to \typewidth{\vrule width\draftrule\hskip\textwidth
           \vrule height\@tempdima width\draftrule\hfill\vrule height\@tempdima width\draftrule}%
           \hrule height\draftrule}%
      \else
         \hbox to \textwidth{\hss\hbox to \typewidth{%
         \vbox to \@tempdima{\hrule height\draftrule
         \vbox to 0pt{\vskip\headheight\vskip\headsep%\vskip-6pt
                \hbox{\vrule height\draftrule width\textwidth}}%
         \hbox to \typewidth{\vrule width\draftrule
         \hfill\vrule height\@tempdima width\draftrule%%\hskip\textwidth\vrule height\@tempdima width\draftrule
}%
         \hrule height\draftrule}}}%
      \fi}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Trimmarks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output Routine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\@outputpage{%
\let\firstmark\botmark
\begingroup%
  \let \protect \noexpand
  \@resetactivechars
  \@parboxrestore
  \shipout \vbox{%
    \set@typeset@protect
    \aftergroup \endgroup
    \aftergroup \set@typeset@protect
  \if@specialpage
    \global\@specialpagefalse\@nameuse{ps@\@specialstyle}%
  \fi
  \reset@font
  \normalsize
  \normalsfcodes
  \let\label\@gobble
  \let\index\@gobble
  \let\glossary\@gobble
  \baselineskip\z@skip \lineskip\z@skip \lineskiplimit\z@
    \@begindvi\trimmarks
    \vskip \topmargin
    \moveright\@themargin \vbox {%
      \setbox\@tempboxa \vbox to\headheight{%
        \vfil
        \color@hbox
          \normalcolor
          \hb@xt@\textwidth{\@thehead}%
        \color@endbox
        }%
      \dp\@tempboxa \z@
      \box\@tempboxa
      \vskip \headsep
      \box\@outputbox
      \baselineskip \footskip
      \color@hbox
        \normalcolor
        \hb@xt@\textwidth{\@thefoot}%
      \color@endbox
      }%
    }%
  \global \@colht \textheight
  \stepcounter{page}%
}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Output Routine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\def\gray{\special{color CMYK 0 0 0 0.5}}
\def\@questionmark{\vbox to 0pt{\vskip13pc\hskip-5pc
                  \hbox to \textwidth{\special{color push}\gray\fontsize{570}{570}\selectfont ?
                  \special{color pop}\hss}}}
\def\questionmark#1{\xdef\@questionmark{#1}}%
%
\def\enddocument{%
   \@enddocumenthook
   \@checkend{document}%
        \immediate\write\@mainaux{\string\endpage{\thepage}}
%
   \clearpage
   \begingroup
     \if@filesw
       \immediate\write\@mainaux{\string\questionmark{}}%
       \immediate\closeout\@mainaux
       \let\@setckpt\@gobbletwo
       \let\@newl@bel\@testdef
       \@tempswafalse
       \makeatletter \input\jobname.aux
     \fi
     \@dofilelist
     \ifdim \font@submax >\fontsubfuzz\relax
       \@font@warning{Size substitutions with differences\MessageBreak
                  up to \font@submax\space have occurred.\@gobbletwo}%
     \fi
     \@defaultsubs
     \@refundefined
     \if@filesw
       \ifx \@multiplelabels \relax
         \if@tempswa
           \@latex@warning@no@line{Label(s) may have changed.
               Rerun to get cross-references right}%
         \fi
       \else
         \@multiplelabels
       \fi
     \fi
   \endgroup
   \deadcycles\z@\@@end}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
\setlength\parskip{0\p@}
\setlength\columnsep{12\p@}
\setlength\columnseprule{0\p@}
\pagestyle{plain}
\pagenumbering{arabic}
\frenchspacing
\sloppy
\onecolumn
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Theorem-like structures %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% In order to match gOMS style, the visual appearance of the three basic
% theorem styles of amsthm.sty is redefined as follows:
%
\newtheoremstyle{plain}%
  {9pt}%       Space above
  {9pt}%       Space below
  {\itshape}%  Body font
  {}%          Indent amount (empty = no indent, \parindent = para indent)
  {\scshape}%  Thm head font
  { }%         Punctuation after thm head
  {0.5em}%     Space after thm head: " " = normal interword space;
         %         \newline = linebreak
  {}%          Thm head spec (can be left empty, meaning `normal')
%
\newtheoremstyle{definition}%
  {9pt}%       Space above
  {9pt}%       Space below
  {}%          Body font
  {}%          Indent amount (empty = no indent, \parindent = para indent)
  {\scshape}%  Thm head font
  { }%         Punctuation after thm head
  {0.5em}%     Space after thm head: " " = normal interword space;
         %         \newline = linebreak
  {}%          Thm head spec (can be left empty, meaning `normal')
%
\newtheoremstyle{remark}%
  {9pt}%       Space above
  {9pt}%       Space below
  {}%          Body font
  {}%          Indent amount (empty = no indent, \parindent = para indent)
  {\itshape}%  Thm head font
  { }%         Punctuation after thm head
  {0.5em}%     Space after thm head: " " = normal interword space;
         %         \newline = linebreak
  {}%          Thm head spec (can be left empty, meaning `normal')
%
% The end-of-proof QED symbol is redefined as follows:
%
\font\QEDlogofont=msam10 at 10pt
\renewcommand\qedsymbol{\hbox{\QEDlogofont\char'004}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%% End Theorem-like structures %%%%%%%%%%%%%%%%%%%%%%%%%%

\endinput
