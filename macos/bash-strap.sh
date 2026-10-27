#!/bin/bash
CUSTOM_NOTATION=$(read -p "Enter custom notation: " input; echo $input)
cat << EOF >> ~/.bashrc
export CUSTOM_NOTATION="$CUSTOM_NOTATION"
EOF
cat << "EOF" >> ~/.bashrc
export PS1="\[\e[38;5;135m\][\A] \
\[\e[38;5;171m\][\u\[\e[38;5;177m\]@\h\[\e[38;5;183m\]]\
\[\e[38;5;212m\]\[\e[212m\][\w] ${CUSTOM_NOTATION}\n\[\e[38;5;105m\]\$? \
\[\e[38;5;139m\][ \$ > \e[38;5;212m"
EOF