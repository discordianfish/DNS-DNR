#!/opt/perl/bin/perl
# $Id: gallery.cgi 172 2008-11-12 12:25:41Z fish $

use strict;
use warnings;
use FindBin qw($RealBin);

use if -e "$RealBin/../Build.PL", lib => "$RealBin/../lib";
use DNS::DNR;

my $webapp = DNS::DNR->new;
$webapp->run;
