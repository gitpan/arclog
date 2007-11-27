#! /usr/bin/perl -w
# Test the errors that should be captured.

# Copyright (c) 2007 imacat
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use warnings;
use diagnostics;
use Test;

BEGIN { plan tests => 22 }

use File::Basename qw(basename);
use File::Path qw(mkpath rmtree);
use File::Spec::Functions qw(catdir catfile updir);
use FindBin;
use lib $FindBin::Bin;
use _helper;
use vars qw($WORKDIR $arclog $tno);

$WORKDIR = catdir($FindBin::Bin, "logs");
$arclog = catfile($FindBin::Bin, updir, "blib", "script", "arclog");
$tno = 0;

# 1: STDIN alone
$_ = eval {
    my ($title, $cmd, $retno, $out, $err, $vardump, $logfile);
    my ($fr, $frb, @fle, $fle, $flr, %cef, %crf, %tef, %trf);
    my ($fs, $cs, %cem);
    rmtree $WORKDIR;
    mkpath $WORKDIR;
    $title = "STDIN alone";
    $logfile = randword;
    $fs = catfile($WORKDIR, $logfile);
    ($cs, $vardump, %cem) = mkrndlog_apache $fs;
    frwrite(catfile($WORKDIR, "$logfile.vardump"), $vardump);
    @fle = qw();
    push @fle, basename($fs);
    push @fle, "$logfile.vardump";
    prsrvsrc $WORKDIR;
    @_ = ($arclog, qw(-d -d -d -c n), "-");
    $cmd = join(" ", @_) . " < " . $fs;
    ($retno, $out, $err) = runcmd $cs, @_;
    ($fle, $flr) = (join(" ", sort @fle), flist $WORKDIR);
    %cef = qw();    # Expected content by file
    %tef = qw();    # Expected file type by file
    %crf = qw();    # Resulted content by file
    %trf = qw();    # Resulted file type by file
    $fr = $fs;
    $frb = basename($fr);
    ($cef{$frb}, $tef{$frb}) = ($cs, TYPE_PLAIN);
    ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
    $frb = "$logfile.vardump";
    $fr = catfile($WORKDIR, $frb);
    ($cef{$frb}, $tef{$frb}) = ($vardump, TYPE_PLAIN);
    ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
    die "$title\n$cmd\n$out$err" unless $retno != 0;
    die "$title\n$cmd\nresult files incorrect.\nGot: $flr\nExpected: $fle\nOutput:\n$out$err"
        unless $flr eq $fle;
    foreach $fr (@fle) {
        die "$title\n$cmd\n$fr: result type incorrect.\nGot: $trf{$fr}\nExpected: $tef{$fr}\nOutput:\n$out$err"
            unless nofile || $trf{$fr} eq $tef{$fr};
        die "$title\n$cmd\n$fr: result incorrect.\nGot:\n$crf{$fr}\nExpected:\n$cef{$fr}\nOutput:\n$out$err"
            unless $crf{$fr} eq $cef{$fr};
    }
    1;
};
ok($_, 1, $@);
cleanup $_, $WORKDIR, ++$tno;

# 2: STDOUT as output prefix
$_ = eval {
    my ($title, $cmd, $retno, $out, $err, $vardump, $logfile);
    my ($fr, $frb, @fle, $fle, $flr, %cef, %crf, %tef, %trf);
    my ($fs, $cs, %cem);
    rmtree $WORKDIR;
    mkpath $WORKDIR;
    $title = "STDOUT as output prefix";
    $logfile = randword;
    $fs = catfile($WORKDIR, $logfile);
    ($cs, $vardump, %cem) = mkrndlog_apache $fs;
    frwrite(catfile($WORKDIR, "$logfile.vardump"), $vardump);
    @fle = qw();
    push @fle, basename($fs);
    push @fle, "$logfile.vardump";
    prsrvsrc $WORKDIR;
    @_ = ($arclog, qw(-d -d -d -c n), $logfile, "-");
    $cmd = join " ", @_;
    ($retno, $out, $err) = runcmd "", @_;
    ($fle, $flr) = (join(" ", sort @fle), flist $WORKDIR);
    %cef = qw();    # Expected content by file
    %tef = qw();    # Expected file type by file
    %crf = qw();    # Resulted content by file
    %trf = qw();    # Resulted file type by file
    $fr = $fs;
    $frb = basename($fr);
    ($cef{$frb}, $tef{$frb}) = ($cs, TYPE_PLAIN);
    ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
    $frb = "$logfile.vardump";
    $fr = catfile($WORKDIR, $frb);
    ($cef{$frb}, $tef{$frb}) = ($vardump, TYPE_PLAIN);
    ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
    die "$title\n$cmd\n$out$err" unless $retno != 0;
    die "$title\n$cmd\nresult files incorrect.\nGot: $flr\nExpected: $fle\nOutput:\n$out$err"
        unless $flr eq $fle;
    foreach $fr (@fle) {
        die "$title\n$cmd\n$fr: result type incorrect.\nGot: $trf{$fr}\nExpected: $tef{$fr}\nOutput:\n$out$err"
            unless nofile || $trf{$fr} eq $tef{$fr};
        die "$title\n$cmd\n$fr: result incorrect.\nGot:\n$crf{$fr}\nExpected:\n$cef{$fr}\nOutput:\n$out$err"
            unless $crf{$fr} eq $cef{$fr};
    }
    1;
};
ok($_, 1, $@);
cleanup $_, $WORKDIR, ++$tno;

# 3-22: Mixing different formats
for (my $i = 0; $i < @LOGFMTS; $i++) {
    for (my $j = 0; $j < @LOGFMTS; $j++) {
        next if $i == $j;
        $_ = eval {
            my ($title, $cmd, $retno, $out, $err, @vardump, %logfiles);
            my ($fr, $frb, @fle, $fle, $flr, %cef, %crf, %tef, %trf);
            my ($num, $swan, @fs, @cs, $opref, $oprfb);
            rmtree $WORKDIR;
            mkpath $WORKDIR;
            $title = join ",", "Mixing formats", ${$LOGFMTS[$i]}{"title"},
                ${$LOGFMTS[$j]}{"title"};
            # 3-5 log files
            $num = 3 + int rand 3;
            $swan = 1 + int rand($num - 1);
            @fs = qw();
            @vardump = qw();
            @fle = qw();
            %logfiles = qw();
            for (my $k = 0; $k < $num; $k++) {
                my ($logfile, $cs, $vardump);
                do { $logfile = randword } while exists $logfiles{$logfile};
                $logfiles{$logfile} = 1;
                push @fs, catfile($WORKDIR, $logfile);
                if ($k != $swan) {
                    ($cs, $vardump, %_) = &{${$LOGFMTS[$i]}{"sub"}}($fs[$k]);
                } else {
                    ($cs, $vardump, %_) = &{${$LOGFMTS[$j]}{"sub"}}($fs[$k]);
                }
                push @cs, $cs;
                push @fle, $logfile;
                push @vardump, $vardump;
                frwrite(catfile($WORKDIR, "$logfile.vardump"), $vardump);
                push @fle, "$logfile.vardump";
            }
            prsrvsrc $WORKDIR;
            do { $oprfb = randword } while exists $logfiles{$oprfb};
            $opref = catfile($WORKDIR, $oprfb);
            @_ = ($arclog, qw(-d -d -d -c n), @fs, $opref);
            $cmd = join " ", @_;
            ($retno, $out, $err) = runcmd "", @_;
            ($fle, $flr) = (join(" ", sort @fle), flist $WORKDIR);
            %cef = qw();    # Expected content by file
            %tef = qw();    # Expected file type by file
            %crf = qw();    # Resulted content by file
            %trf = qw();    # Resulted file type by file
            for (my $k = 0; $k < $num; $k++) {
                $fr = $fs[$k];
                $frb = basename($fr);
                ($cef{$frb}, $tef{$frb}) = ($cs[$k], TYPE_PLAIN);
                ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
                $frb = "$frb.vardump";
                $fr = catfile($WORKDIR, $frb);
                ($cef{$frb}, $tef{$frb}) = ($vardump[$k], TYPE_PLAIN);
                ($crf{$frb}, $trf{$frb}) = (fread $fr, ftype $fr);
            }
            die "$title\n$cmd\n$out$err" unless $retno != 0;
            die "$title\n$cmd\nresult files incorrect.\nGot: $flr\nExpected: $fle\nOutput:\n$out$err"
                unless $flr eq $fle;
            foreach $fr (@fle) {
                die "$title\n$cmd\n$fr: result type incorrect.\nGot: $trf{$fr}\nExpected: $tef{$fr}\nOutput:\n$out$err"
                    unless nofile || $trf{$fr} eq $tef{$fr};
                die "$title\n$cmd\n$fr: result incorrect.\nGot:\n$crf{$fr}\nExpected:\n$cef{$fr}\nOutput:\n$out$err"
                    unless $crf{$fr} eq $cef{$fr};
            }
            1;
        };
        ok($_, 1, $@);
        cleanup $_, $WORKDIR, ++$tno;
        die unless $_;
    }
}
