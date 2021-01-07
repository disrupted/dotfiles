" Check Python files with flake8 and pylint.
" let b:ale_linters = ['mypy']
" Fix Python files with autopep8 and yapf.
let b:ale_fixers = ['autopep8', 'isort', 'black', 'remove_trailing_lines', 'trim_whitespace']
" Disable warnings about trailing whitespace for Python files.
" let b:ale_warn_about_trailing_whitespace = 0
