vim9script

# Globals {{{
g:ImgpasteFormatMap = extend(
    {
        'markdown': 'markdown',
        'tex': 'tex',
        'plaintex': 'tex',
    },
    get(g:, 'ImgpasteFormatMap', {})
)

if !exists("g:ImgpasteRootDir")
    g:ImgpasteRootDir = "images"
endif
if !exists("g:ImgpasteDefaultName")
    g:ImgpasteDefaultName = "%Y%m%d-%H%M%S.png"
endif
# }}}
# Local config {{{
var scriptdir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h') .. "/scripts/"
# }}}

def GetCmdLine(confirm: bool = false): list<string>
    var os = "Windows"
    var fscript = 'img-paste.ps1'
    if !(has("win64") || has("win32") || has("win16"))
        os = substitute(system('uname'), '\n', '', '')
        fscript = 'img-paste.sh'
    endif



    var rstr = printf('%06x', rand() % 0xffffff)
    var pattern = substitute(g:ImgpasteDefaultName, '%R', rstr, 'g')
    var imgsubpath = strftime(pattern)
    var img_output_path = g:ImgpasteRootDir .. '/' .. imgsubpath

    if confirm
        img_output_path = input("Image path (leave blank to cancel): ", img_output_path)
        if img_output_path == ""
            return []
        endif
    endif

    var cmdline = scriptdir .. '/' .. fscript .. ' ' .. img_output_path

    if os == "Windows"
        cmdline = substitute(cmdline, '/', '\\', 'g')
    endif

    return [ cmdline, img_output_path ]
enddef


export def InsertImage(confirm: bool = false, print: bool = true)
    var Printer: func = null_function

    if print
        if exists("g:ImgpasteFormatters") && g:ImgpasteFormatters->has_key(&ft)
            Printer = g:ImgpasteFormatters[&ft]
        else
            if !exists("*imgpaste#formatters#" .. &ft .. "#Format")
                # Force-load the autoload file, if it exists
                # This doesn't seem to have any effect if the file doesn't exist,
                # so no error handling required
                # In an exists() block because why not?
                exec "runtime autoload/imgpaste/formatters/" .. &ft .. ".vim"
            endif
            if exists("*imgpaste#formatters#" .. &ft .. "#Format")
                Printer = funcref("imgpaste#formatters#" .. &ft .. "#Format")
            endif
        endif

        if (Printer == null_function)
            echoerr "Image pasting not supported for this filetype:" &ft 
            return
        endif
    endif
    var res = GetCmdLine(confirm)
    if res->len() == 0
        echo "Image paste aborted"
        return
    endif
    var cmdline = res[0]
    var path = res[1]

    var execRes = system(cmdline)

    if v:shell_error != 0
        echo execRes
        return
    endif

    if print
        Printer(path)
    endif
enddef
