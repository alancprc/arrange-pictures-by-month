#!/usr/bin/env perl

use 5.010.001;
use Function::Parameters;
use Types::Standard qw(Str Int ArrayRef RegexpRef);
use JSON -convert_blessed_universally;
use Image::ExifTool qw(:Public);
use File::Basename;
use File::Spec;
use File::Path qw(make_path remove_tree);
use Carp qw(croak carp);

my $config;    # configs read from json file.

sub main
{
    $config = &readConfigFile("config.json");
    my @src   = @{ $config->{'folder'} };
    my @files = `find @src -type f`;
    chomp @files;

    for my $file (@files) {
        say $file if $config->{'debug'};
        my $dst = &getTargetDirectory($file);
        &copyToFolder( $file, $dst );
    }
}

fun getTargetDirectory ( $file )
{
    my ( $year, $month ) = &getYearMonth($file);
    my $path = $config->{'target'} ? $config->{'target'} : ".";
    return File::Spec->catdir( $path, $year . $config->{'delimiter'} . $month );
}

# get year, month by reading exif
fun getYearMonth ( $file )
{

=pod
 FileModifyDate                   : 2019:08:13 09:21:48+08:00

 MIMEType                         : image/jpeg
 DateTimeOriginal                 : 2019:08:13 09:21:50

 MIMEType                         : video/quicktime
 CreateDate                       : 2018:10:29 13:02:01
=cut

    my $exifTool = new Image::ExifTool;
    $exifTool->Options( Unknown => 1 );
    my $info = $exifTool->ImageInfo($file);

    my $time = $info->{'FileModifyDate'};
    if ( $info->{'MIMEType'} =~ /image/i and $info->{'DateTimeOriginal'} ) {
        $time = $info->{'DateTimeOriginal'};
    } elsif ( $info->{'MIMEType'} =~ /video/i and $info->{'CreateDate'} ) {
        $time = $info->{'CreateDate'};
    } else {
    }
    my @fields = split /:/, $time;
    say "@fields[0,1]" if $config->{'debug'};
    return @fields[ 0, 1 ];
}

# copy file to target directory $dst.
# if $dst/$file exists and differ from $file, do nothing.
fun copyToFolder ( $file, $dst )
{
    system("mkdir -p $dst") unless -e $dst;

    my $fn = basename $file;
    if ( -e "$dst/$fn" and "$dst/$fn" eq $file ) {
        say "'$dst/$fn' and '$file' are the same file";
        return;
    }
    if ( -e "$dst/$fn" and isDiff( $file, "$dst/$fn" ) ) {
        say "'$dst/$fn' exists and differ from '$file'";
        return;
    }
    my $cmd = $config->{'command'};
    system("$cmd $file $dst");
}

fun isDiff ( $first, $second )
{
    return `diff -q $first $second`;
}

fun getDirnameFilename (Str $file, Str $path=".")
{
    my $dir      = dirname $file;
    my $filename = basename $file;
    $dir = File::Spec->catdir( $path, $dir ) if ($path);
    my $fullname = File::Spec->catfile( $dir, $filename );
    return ( $dir, $filename, $fullname );
}

fun openFile (Str $file, Str :$path=".", Str :$mode = '<')
{
    my ( $dir, $filename, $fullname ) = getDirnameFilename( $file, $path );

    make_path( $dir, { mode => 0777 } ) if $dir;
    open my $fh, $mode, $fullname or croak "cannot access $fullname\n";
    return $fh;
}

fun getFileContent (Str $file, Str :$path=".")
{
    my $fh  = openFile( $file, path => $path ) or croak "$file $!";
    my @tmp = <$fh>;
    close($fh);
    return @tmp;
}

fun readConfigFile ( $filename )
{
    my @data        = &getFileContent($filename);
    my $onelinedata = join "\n", @data;
    return from_json($onelinedata);
}

&main();
