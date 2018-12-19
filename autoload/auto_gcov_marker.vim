if exists('g:autoloaded_auto_gcov_marker') || &cp || version < 700
    finish
else
    if !exists("g:auto_gcov_marker_line_covered")
        let g:auto_gcov_marker_line_covered = '✓'
    endif
    if !exists("g:auto_gcov_marker_line_uncovered")
        let g:auto_gcov_marker_line_uncovered = '✘'
    endif
    if !exists("g:auto_gcov_marker_branch_covered")
        let g:auto_gcov_marker_branch_covered = '✓✓'
    endif
    if !exists("g:auto_gcov_marker_branch_partly_covered")
        let g:auto_gcov_marker_branch_partly_covered = '✓✘'
    endif
    if !exists("g:auto_gcov_marker_branch_uncovered")
        let g:auto_gcov_marker_branch_uncovered = '✘✘'
    endif
    if !exists("g:auto_gcov_marker_gcov_path")
        let g:auto_gcov_marker_gcov_path = '.'
    endif
    if !exists("g:auto_gcov_marker_gcno_path")
        let g:auto_gcov_marker_gcno_path = '.'
    endif

    if !hlexists('GcovLineCovered')
        highlight GCovLineCovered ctermfg=green guifg=green
    endif
    if !hlexists('GcovLineUncovered')
        highlight GCovLineUncovered ctermfg=red guifg=red
    endif
    if !hlexists('GcovBranchCovered')
        highlight GCovBranchCovered ctermfg=green guifg=green
    endif
    if !hlexists('GcovBranchPartlyCovered')
        highlight GCovBranchPartlyCovered ctermfg=yellow guifg=yellow
    endif
    if !hlexists('GcovBranchUncovered')
        highlight GCovBranchUncovered ctermfg=red guifg=red
    endif
endif

function auto_gcov_marker#BuildCov(...)
    let filename = expand('%:t:r')
    let gcno = globpath(g:auto_gcov_marker_gcno_path, '/**/' . filename . '.gcno', 1, 1)
    if len(gcno) == '0'
        echo "gcno file not found"
        return
    elseif len(gcno) != '1'
        echo "too many gcno files"
        return
    endif
    let gcno = fnamemodify(gcno[0], ':p')

    silent exe '!(cd ' . g:auto_gcov_marker_gcov_path . '; gcov -i -b -m ' . gcno . ') > /dev/null'
    redraw!

    let gcov = g:auto_gcov_marker_gcov_path . '/' . expand('%:t') . '.gcov'

    call auto_gcov_marker#SetCov(gcov)
endfunction

function auto_gcov_marker#ClearCov(...)
    " FIXME: Only gcov tags should be cleared, not all of them
    exe ":sign unplace *"
endfunction

function auto_gcov_marker#SetCov(...)
    if(a:0 == 1)
        let filename = a:1
    else
        return
    endif

    " Clear previous markers.
    call auto_gcov_marker#ClearCov()

    " Prepare signs
    exe ":sign define gcov_line_covered texthl=GcovLineCovered text=" . g:auto_gcov_marker_line_covered
    exe ":sign define gcov_line_uncovered texthl=GcovLineUncovered text=" . g:auto_gcov_marker_line_uncovered
    exe ":sign define gcov_branch_covered texthl=GcovBranchCovered text=" . g:auto_gcov_marker_branch_covered
    exe ":sign define gcov_branch_partly_covered texthl=GcovBranchPartlyCovered text=" . g:auto_gcov_marker_branch_partly_covered
    exe ":sign define gcov_branch_uncovered texthl=GcovBranchUncovered text=" . g:auto_gcov_marker_branch_uncovered

    " Read files and fillin marks dictionary
    let marks = {}
    try
        let gcovfile = readfile(filename)
    catch
        echo "Failed to read gcov file"
        return
    endtry

    for line in gcovfile
        let type = split(line, ':')[0]
        let linenum = split(line, '[:,]')[1]

        if type == 'lcount'
            let execcount = split(line, '[:,]')[2]
            if execcount == '0'
                let marks[linenum] = 'lineuncovered'
            else
                let marks[linenum] = 'linecovered'
            endif
        endif

        if type == 'branch'
            let branchcoverage = split(line, '[:,]')[2]
            if branchcoverage == 'notexec'
                if !has_key(marks, linenum) || marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchuncovered'
                    let marks[linenum] = 'branchuncovered'
                endif
                if marks[linenum] == 'linecovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchcovered'
                    let marks[linenum] = 'branchpartlycovered'
                endif

            elseif branchcoverage == 'taken'
                if !has_key(marks, linenum) || marks[linenum] == 'linecovered' || marks[linenum] == 'branchcovered'
                    let marks[linenum] = 'branchcovered'
                endif
                if marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchcovered'
                    let marks[linenum] = 'branchpartlycovered'
                endif

            elseif branchcoverage == 'nottaken'
                if !has_key(marks, linenum) || marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchuncovered'
                    let marks[linenum] = 'branchuncovered'
                endif
                if marks[linenum] == 'linecovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchcovered'
                    let marks[linenum] = 'branchpartlycovered'
                endif

            endif
        endif
    endfor

    " Iterate over marks dictionary and place signs
    for [line, marktype] in items(marks)
        if marktype == 'linecovered'
            exe ":sign place " . line. " line=" . line . " name=gcov_line_covered file=" . expand("%:p")
        elseif marktype == 'lineuncovered'
            exe ":sign place " . line . " line=" . line . " name=gcov_line_uncovered file=" . expand("%:p")
        elseif marktype == 'branchcovered'
            exe ":sign place " . line . " line=" . line . " name=gcov_branch_covered file=" . expand("%:p")
        elseif marktype == 'branchpartlycovered'
            exe ":sign place " . line . " line=" . line . " name=gcov_branch_partly_covered file=" . expand("%:p")
        elseif marktype == 'branchuncovered'
            exe ":sign place " . line . " line=" . line . " name=gcov_branch_uncovered file=" . expand("%:p")
        endif
    endfor

    " Set the coverage file for the current buffer
    let b:coveragefile = fnamemodify(filename, ':p')
endfunction

let g:autoloaded_auto_gcov_marker = 1
