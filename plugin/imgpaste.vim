vim9script

import autoload "imgpaste.vim" as ip

nnoremap <C-i> <ScriptCmd>ip.InsertImage(true)<cr>
nnoremap <M-i> <ScriptCmd>ip.InsertImage(true, false)<cr>
