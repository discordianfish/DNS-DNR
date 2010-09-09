package DNS::DNR;

use warnings;
use strict;

use FindBin qw($RealBin $Bin);
use File::Spec::Functions qw(catfile);

use CGI::Application;
use base 'CGI::Application';

use CGI::Application::Plugin::Config::Simple;
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);

=head1 NAME

DNS::DNR - dynamic name registration

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Small webapp to for updating a database, ment to use with powerdns or
any sql based nameserver

see examples/dnr.cgi how to use it

=head1 FUNCTIONS

=head2 setup

=cut

sub setup
{
	my $self = shift;

	$self->run_modes
	(
		update => 'rm_update',
		register => 'rm_register',
	);
	$self->start_mode('update');
	$self->error_mode('rm_error');
}

=head2 setup

=cut

sub cgiapp_init
{
	my $self = shift;
	$self->config_file($ENV{CONFIG} || $self->param('config') || catfile $RealBin, 'dnr.conf');
	$self->dbh_config($self->config_param('global.dsn')) or die "could net setup dbh (wrong dsn string?";
}

=head2 rm_error

dispalys a error

=cut

sub rm_error
{
	my $self = shift;
	my $error = join ', ', @_;

	my $output = join '',
		$self->query->start_html(-title => "Error"),
		$self->query->h1("Error"),
		$self->query->p("$error"),
		$self->query->end_html;
	return $output;
}

=head2 rm_update

update a name

=cut

sub rm_update
{
	my $self = shift;
	my $user = $self->query->param('user');
	my $password = $self->query->param('password');
	my $rdata = $self->query->param('rdata');
		die "no rdata support atm" if $rdata;

	my $cn = $self->config_param('users.'.$user) or die "invalid user '$user'"; # FIXME: there should be no difference between wrong user or password
	my @names = split /\s+/, $cn;
	my $password_stored = shift @names; # password = first field

	die "invalid user/password" unless $password eq $password_stored;

	$rdata = $self->query->remote_addr;
	#::ffff:92.224.173.241
	$rdata =~ s/^::ffff://; #only v4 atm

	warn "updating zones (@names) for $user:$password with $rdata";
	for my $name (@names)
	{
		$self->update($name, $rdata);
	}
	return "Done";
}

=head2 update

update a name

=cut

sub update
{
	my $self = shift;
	my $name = shift;
	my $rdata = shift;

	my @owner_p;
	my @labels = split /\./, $name;
	#( gaia, 42o, de ]
	
	push @owner_p, shift @labels while not $self->is_zone(@labels);
    my $zone = join '.', @labels;
    my $owner = join '.', @owner_p;
    my $time = time;

	my $sth;
    $sth = $self->dbh->prepare(join ',', $self->config_param('global.select_soa_sql')) or die $!;
    $sth->execute('SOA', $zone);
    my @soa = split /\s+/, ($sth->fetchrow_array)[0];
    use Data::Dumper;
    warn Dumper(\@soa);

	warn "adding $owner in $zone (" . join ' ', @soa . ")\n\n";
    $soa[2]++; # serial is defined as third space deiimited element in soa record


   
    $sth = $self->dbh->prepare( join ',', $self->config_param('global.update_sql') ) or die $!;
	$sth->execute($rdata, $time, 'A', $name, $zone) or die "could not update: $!";

    $sth = $self->dbh->prepare($self->config_param('global.update_soa_sql')) or die $!;
    $sth->execute(join(' ', @soa), 'SOA', $zone) or die "could not update: $!";
}

=head2 is_zone

checks whether argument is a existing zone

=cut

sub is_zone
{
	my $self = shift;
	my $zone = join '.', @_;
	die "not found" unless $zone;
	my $sql = join ',', $self->config_param('global.zone_sql');
	my $sth = $self->dbh->prepare($sql) or die $!;
	$sth->execute($zone);
        my @arr = $sth->fetchrow_array;
	return 1 if @arr; # returns rdata -> soa record
}

=head1 AUTHOR

Johannes 'fish' Ziemke, C<< <cpan at the domain called freigeist which belongs to the TLD org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xvz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DNS::DNR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DNS::DNR::FE::CAP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DNS::DNR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DNS::DNR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DNS::DNR>

=item * Search CPAN

L<http://search.cpan.org/dist/DNS::DNR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Johannes 'fish' Ziemke, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DNS::DNR::FE::CAP
