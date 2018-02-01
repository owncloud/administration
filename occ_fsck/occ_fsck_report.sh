#! /bin/sh

dir=$1

if [ ! -d "$dir" ]; then
  echo "Usage: $0 dir"
  echo "   dir is the output folder of a finished or ongoing run of occ_fsch.sh"
  exit 1
fi

cat  $dir/good.log >  $dir/fileids_seen.out
sed < $dir/bad.log >> $dir/fileids_seen.out -n -e 's/E: fileid=\([0-9]*\) .*/\1/p'

echo
printf "%8d total filecache entries seen.\n"			$(wc -l < $dir/fileids_seen.out)
printf "%8d files with good filecache entries.\n"               $(wc -l < $dir/good.log)
printf "%8d files with entries with NULL or empty checksum.\n"  $(grep ' checksum is ' $dir/bad.log | wc -l)
printf "%8d files with size or mtime mismatch.\n"  		$(egrep ' (mtime|size) mismatch: ' $dir/bad.log | wc -l)
printf "%8d files with checksum mismatch.\n"  			$(grep  ' checksum mismatch: ' $dir/bad.log | wc -l)
printf "%8d files without filecache entries.\n"                 $(grep -v ' fileid=' $dir/bad.log | wc -l)

