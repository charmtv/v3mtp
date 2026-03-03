import os
script_lines = [
    '#!/bin/bash',
    '# Telemt v3 - https://github.com/charmtv/v3mtp',
    "B='\\033[1m'",
    "DIM='\\033[2m'",
    "NC='\\033[0m'",
    'CF=/etc/telemt.toml',
    'BP=/usr/local/bin/telemt',
    'SF=/etc/systemd/system/telemt.service',
    'GH=https://github.com/charmtv/v3mtp',
    'banner() {',
    '    clear',
    '    echo ""',
    '    echo -e "${B}=================================================${NC}"',
    '    echo -e "${B}        Telemt v3 \\xe7\\xae\\xa1\\xe7\\x90\\x86\\xe5\\xb7\\xa5\\xe5\\x85\\xb7${NC}"',
    '    echo -e "${B}     \\xe9\\xab\\x98\\xe6\\x80\\xa7\\xe8\\x83\\xbd Telegram MTProto \\xe4\\xbb\\xa3\\xe7\\x90\\x86${NC}"',
    '    echo -e "${B}${NC}"',
    '    echo -e "${B}  by: \\xe7\\xb1\\xb3\\xe7\\xb2\\x92${NC}"',
    '    echo -e "${B}  TG\\xe7\\xbe\\xa4: https://t.me/mlkjfx6${NC}"',
    '    echo -e "${B}=================================================${NC}"',
    '    echo ""',
    '}',
]
# I realize this approach is getting too complex. Let me just write the file directly.
print("skip")
