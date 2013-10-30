#!/bin/bash

# script to sum up multiple lines of du output

#[observer][root ~]$  du -sx /home/cvs/ /var/cvs/ /home/tennsat/ /home/drkerr/
#/home/kpri/ /var/lib/mysql/ /home/ssc_org/ /home/ssc_com/ /home/wsd/
#/home/ssldocs/ /home/affm/ /home/brian/[a-zA-Z]* | cut -f 1 | perl -e
#'while(<STDIN>){$sum +=$_;} print $sum."\n";'
#787856
#[observer][root ~]$  du -sx /home/cvs/ /var/cvs/ /home/tennsat/ /home/drkerr/
#/home/kpri/ /var/lib/mysql/ /home/ssc_org/ /home/ssc_com/ /home/wsd/
#/home/ssldocs/ /home/affm/ /home/brian/[a-zA-Z]* | perl -ne '/^ *([0-9]+)/ and
#$sum += $1; if (eof()){print("$sum\n");}'
#787856

#/usr/bin/du -sx \
#/home/cvs/ /var/cvs/ /home/tennsat/ /home/drkerr/ /home/kpri/ /var/lib/mysql/ \
# /home/ssc_org/ /home/ssc_com/ /home/wsd/ /home/ssldocs/ /home/affm/ \
#/home/brian/[a-zA-Z]* | \
#perl -ne '/^ *([0-9]+)/ and $sum += $1; if (eof()){print("$sum\n");}'

# du -s combos/ deathmatch/ docs/ graphics/ historic/ incoming/ levels/ lmps/
# misc/ music/ newstuff/ prefabs/ roguestuff/ skins/ sounds/ source/ themes/
# utils/ | awk '{total += $1}; END { print "total disk usage is", total}'

IDGAMES_MIRROR_DIR="/home/idgames/html"
IDGAMES_WAD_DIRS="combos deathmatch deathmatch/skulltag deathmatch/deathtag
    levels/doom levels/doom2 newstuff
" # IDGAMES_WAD_DIRS

for WAD_DIR in $IDGAMES_WAD_DIRS;
do
    echo "Checking WAD directory: ${WAD_DIR}"
    /usr/bin/find \
        $IDGAMES_MIRROR_DIR/$WAD_DIR \
        -name "*.txt" \
        -exec stat --format "%s" '{}' \; \
    | perl -ne '/^ *([0-9]+)/ and $sum += $1; if (eof()){print("$sum\n");}'
done

