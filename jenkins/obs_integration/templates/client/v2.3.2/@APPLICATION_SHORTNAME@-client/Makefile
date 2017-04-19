#
# generate meta files from their *.in using prjconf 
# 
# jw, 20170207 initial draught
# jw, 20170213 added /g
#
## convert %define variables from prjconf into sed substitute expressions.

metafiles:
	PRJCONF_DEFS=$$(osc meta prjconf | grep %define); \
	SUBST=$$(echo "$$PRJCONF_DEFS" | sed -e 's/^%define\s*//' -e "s/^\([^\s]*\)\s\s*\(.*\)/-e 's@\$${\1}@\2@g'/g"); echo "$$PRJCONF_DEFS"; \
	for file in *.in; do \
  	  rm -f $$(basename $$file .in); \
  	  eval sed $$SUBST $$file > $$(basename $$file .in); \
  	  chmod a-w $$(basename $$file .in); \
	done \
