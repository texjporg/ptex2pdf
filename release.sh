#
# release.sh
# copied from jfontmaps project and adapted

PROJECT=ptex2pdf
DIR=`pwd`
VER=${VER:-`date +%Y%m%d.0`}

TEMP=/tmp

echo "Making Release $VER. Ctrl-C to cancel."
read REPLY
if test -d "$TEMP/$PROJECT-$VER"; then
  echo "Warning: the directory '$TEMP/$PROJECT-$VER' is found:"
  echo
  ls $TEMP/$PROJECT-$VER
  echo
  echo -n "I'm going to remove this directory. Continue? yes/No"
  echo
  read REPLY <&2
  case $REPLY in
    y*|Y*) rm -rf $TEMP/$PROJECT-$VER;;
    *) echo "Aborted."; exit 1;;
  esac
fi
echo
git commit -m "Release $VER" --allow-empty
git archive --format=tar --prefix=$PROJECT-$VER/ HEAD | (cd $TEMP && tar xf -)
#
cd $TEMP/$PROJECT-$VER
# unnecessary for CTAN upload
FILEREMOVAL=".gitignore ptex2pdf-tlpost.pl Makefile release.sh"
rm -f $FILEREMOVAL
# make now a orig copy so that we see that the version update worked
cd $TEMP
rm -rf $PROJECT-$VER-orig
cp -r $PROJECT-$VER $PROJECT-$VER-orig
# update version number
cd $TEMP/$PROJECT-$VER
for i in ptex2pdf.lua ; do
  perl -pi.bak -e "s/\\\$VER\\\$/$VER/g" $i
  rm -f ${i}.bak
done
cd $TEMP
echo "Files removed for CTAN upload: $FILEREMOVAL"
diff -urN $PROJECT-$VER-orig $PROJECT-$VER
tar zcf $DIR/$PROJECT-$VER.tar.gz $PROJECT-$VER
rm -rf $PROJECT-$VER-orig
rm -rf $PROJECT-$VER
echo
echo You should execute
echo
echo "  git push && git tag $VER && git push origin $VER"
echo
echo Informations for submitting CTAN: 
echo "  CONTRIBUTION: $PROJECT"
echo "  VERSION:      $VER"
echo "  AUTHOR:       Japanese TeX Development Community"
echo "  SUMMARY:      Convert Japanese TeX documents to PDF"
echo "  DIRECTORY:    language/japanese/$PROJECT"
echo "  LICENSE:      free/GPLv2"
echo "  FILE:         $DIR/$PROJECT-$VER.tar.gz"

