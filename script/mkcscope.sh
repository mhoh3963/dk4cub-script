rm tags
ctags -R .

rm cscope.files cscope.out
find . \( -name '*.c' -o -name '*.h' -o -name '*.s' -o -name '*.S' \) -print > cscope.files
cscope -i cscope.files
