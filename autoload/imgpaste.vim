vim9script

# Globals {{{
g:ImgpasteFormatMap = extend(
    {
        'markdown': 'markdown',
        'tex': 'tex'
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


def GetCmdLine(): list<string>
    var os = "Windows"
    var fscript = 'img-paste.ps1'
    if !(has("win64") || has("win32") || has("win16"))
        os = substitute(system('uname'), '\n', '', '')
        fscript = 'img-paste.sh'
    endif

    var ch = g:ImgpasteRootDir[0]
    var outroot: string = ""
    outroot = expand('%:p:h') .. '/' .. g:ImgpasteRootDir

    var rstr = printf('%06x', rand() % 0xffffff)
    var pattern = substitute(g:ImgpasteDefaultName, '%R', rstr, 'g')
    var imgsubpath = strftime(pattern)
    var imgfullpath = outroot .. '/' .. imgsubpath

    var cmdline = scriptdir .. '/' .. fscript .. ' ' .. imgfullpath

    if os == "Windows"
        cmdline = substitute(cmdline, '/', '\\', 'g')
    endif

    return [ cmdline, imgfullpath ]
enddef


export def InsertImage()
    var Printer: func = null_function

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
    var res = GetCmdLine()
    var cmdline = res[0]
    var path = res[1]

    var execRes = system(cmdline)

    if v:shell_error != 0
        echo execRes
        return
    endif

    Printer(path)
enddef
