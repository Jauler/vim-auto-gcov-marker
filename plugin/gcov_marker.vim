if exists('g:loaded_gcov_marker') || &cp || version < 700
    finish
endif

command! -bang -nargs=* -complete=file GcovLoad call gcov_marker#SetCov(<f-args>)
command! -bang -nargs=0 GcovBuild call gcov_marker#BuildCov()
command! -bang -nargs=0 GcovClear call gcov_marker#ClearCov()

let g:loaded_gcov_marker = 1
