target=arrange-photos-by-month.pl
all : run

run :
	chmod u+x ${target}
	./${target}
