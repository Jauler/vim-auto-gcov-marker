if exists('g:autoloaded_gcov_marker') || &cp || version < 700
    finish
else
    if !exists("g:gcov_marker_covered")
        let g:gcov_marker_covered = '✓'
    endif
    if !exists("g:gcov_marker_uncovered")
        let g:gcov_marker_uncovered = '✘'
    endif
    if !exists("g:gcov_marker_auto_lopen")
        let g:gcov_marker_auto_lopen = 1
    endif
    if !exists("g:gcov_marker_path")
        let g:gcov_marker_path = '.'
    endif
    if !exists("g:gcov_gcno_path")
        let g:gcov_gcno_path = '.'
    endif
endif

function gcov_marker#BuildCov(...)
    let filename = expand('%:t:r')
    let gcno = globpath(g:gcov_gcno_path, '/**/' . filename . '.gcno', 1, 1)
    if len(gcno) == '0'
        echo "gcno file not found"
        return
    elseif len(gcno) != '1'
        echo "too many gcno files"
        return
    endif
    let gcno = fnamemodify(gcno[0], ':p')

    silent exe '!pushd ' . g:gcov_marker_path . '; gcov -i -b -m ' . gcno . ' > /dev/null; popd'

    let gcov = g:gcov_marker_path . expand('%:t') . '.gcov'

    call gcov_marker#SetCov('<bang>', gcov)
    redraw!
endfunction

function gcov_marker#FindCov(...)
    if (a:0 == 1)
        if(a:1 == '!')
            exe ":sign unplace *"
            return
        endif
    endif
    let filename = expand('%:t')
    let files = split(globpath(g:gcov_marker_path, filename . ".gcov"), '\n')
    if (len(files) == 0)
        echoerr "could not find any file named " . filename . ".gcov"
        return
    endif
    " check current file name matches Source
    for file in files
        for line in readfile(file)
            if line =~ 'file:.*'
                let d = split(line, ':')
                let n = substitute(d[1], " *", "", "")
                if n == expand('%:p')
                    echo "load file " . file . " for coverage"
                    call gcov_marker#SetCov('<bang>', file)
                    return
                endif
            endif
        endfor
    endfor
endfunction

function gcov_marker#SetCov(...)
    if(a:0 == 2)
        let filename = a:2
    elseif (a:0 == 1)
        if(a:1 == '!')
            exe ":sign unplace *"
            return
        endif
        if(exists("b:coveragefile") && b:coveragefile != '')
            let filename = b:coveragefile
        else
            echoerr "no file for buffer specified yet"
            return
        endif
    else
        return
    endif
    "Clear previous markers.
    exe ":sign unplace *"
    let currentfile = expand('%')

    exe ":highlight GcovUncoveredText ctermfg=red guifg=red"
    exe ":highlight GcovPartlyCoveredText   ctermfg=yellow guifg=yellow"
    exe ":highlight GcovCoveredText   ctermfg=green guifg=green"

    "Read coverage file (work only without branch coverage at the moment )
    exe ":sign define gcov_both_covered texthl=GcovCoveredText text=" . g:gcov_marker_covered . g:gcov_marker_covered
    exe ":sign define gcov_line_covered texthl=GcovCoveredText text=" . g:gcov_marker_covered
    exe ":sign define gcov_branch_uncovered texthl=GcovPartlyCoveredText text=" . g:gcov_marker_covered . g:gcov_marker_uncovered
    exe ":sign define gcov_uncovered texthl=GcovUncoveredText text=" . g:gcov_marker_uncovered
    exe ":sign define gcov_both_uncovered texthl=GcovUncoveredText text=" . g:gcov_marker_uncovered . g:gcov_marker_uncovered

    for line in readfile(filename)
        if line =~ 'lcount:.*'
            let d = split(line, ':')
            let d = split(d[1], ',')
            let l = substitute(d[0], " *", "", "")
            let c = substitute(d[1], " *", "", "")
            if '0' != c
                exe ":sign place " . l . " line=" . l . " name=gcov_line_covered file=" . expand("%:p")
            else
                exe ":sign place " . l . " line=" . l . " name=gcov_uncovered file=" . expand("%:p")
            endif
        endif
        if line =~ 'branch:.*'
            let d = split(line, ':')
            let d = split(d[1], ',')
            let l = substitute(d[0], " *", "", "")
            let s = substitute(d[1], " *", "", "")
            if s =~ 'taken'
                exe ":sign place " . l . " line=" . l . " name=gcov_both_covered file=" . expand("%:p")
            endif
        endif
    endfor
    for line in readfile(filename)
        if line =~ 'branch:.*'
            let d = split(line, ':')
            let d = split(d[1], ',')
            let l = substitute(d[0], " *", "", "")
            let s = substitute(d[1], " *", "", "")
            if s =~ 'nottaken'
                exe ":sign place " . l . " line=" . l . " name=gcov_branch_uncovered file=" . expand("%:p")
            elseif s =~ 'notexec'
                exe ":sign place " . l . " line=" . l . " name=gcov_both_uncovered file=" . expand("%:p")
            endif
        endif
    endfor

    " Set the coverage file for the current buffer
    let b:coveragefile = fnamemodify(filename, ':p')
endfunction

let g:autoloaded_gcov_marker = 1
