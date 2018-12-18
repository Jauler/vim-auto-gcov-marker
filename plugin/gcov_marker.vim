if exists('g:loaded_gcov_marker') || &cp || version < 700
    finish
endif

command! -bang -nargs=* -complete=file GcovLoad call gcov_marker#SetCov('<bang>',<f-args>)
command! -bang -nargs=0 GcovFind call gcov_marker#FindCov('<bang>')
command! -bang -nargs=0 GcovBuild call gcov_marker#BuildCov('<bang>')


let g:loaded_gcov_marker = 1
