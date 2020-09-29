# gw150914-fig4b
Instructions for Reproducing the PyCBC GW150914 Discovery Plot

## LaTeX Installation

Download http://mirrors.ctan.org/fonts/arev.zip and unzip

cp -R arev/tex/latex/arev /usr/share/texlive/texmf-local/texmf-compat/tex/latex
cp -R arev/fonts /usr/share/texlive/texmf-local/texmf-compat/fonts
mktexlsr
updmap-sys --force --enable Map=arev.map
mktexlsr

yum install texlive-mathdesign

