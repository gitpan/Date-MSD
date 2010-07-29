use warnings;
use strict;

use Test::More tests => 1 + 8*2*3*3*4;

BEGIN {
	use_ok "Date::MSD",
		qw(msd_to_msd msd_to_jsn jsn_to_cmsd cmsdn_to_cmsdn);
}

my $have_bigrat = eval("use Math::BigRat 0.04; 1");

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

my @prep = (
	sub { $_[0] },
	sub { $have_bigrat ? Math::BigRat->new($_[0]) : undef },
);

my %zoneful = (
	msd => 0,
	js => 0,
	cmsd => 1,
);

sub flr($) {
	my($n) = @_;
	if(ref($n) eq "Math::BigRat") {
		return $n->copy->bfloor;
	} else {
		my $i = int($n);
		return $i == $n || $n > 0 ? $i : $i - 1;
	}
}

sub check($$) {
	my($dates, $zone) = @_;
	foreach my $src (keys %$dates) { foreach my $dst (keys %$dates) {
		my $sd = $dates->{$src};
		my $dd = $dates->{$dst};
		my @zone = $zoneful{$src} == $zoneful{$dst} ? () : ($zone);
		foreach my $prep (@prep) { SKIP: {
			my $psd = $prep->($sd);
			my $pdd = $prep->($dd);
			skip "numeric type unavailable", 8
				unless defined($psd) && defined($pdd);
			my $func = \&{"Date::MSD::${src}_to_${dst}"};
			match $func->($psd, @zone), $pdd;
			$func = \&{"Date::MSD::${src}_to_${dst}n"};
			my $dn0 = $func->($psd, @zone);
			my($dn1, $dtod) = $func->($psd, @zone);
			match $dn0, $dn1;
			ok $dtod >= 0 && $dtod < 1;
			match $dn1 + $dtod, $pdd;
			$func = \&{"Date::MSD::${src}n_to_${dst}"};
			my $psdn = flr($psd);
			my $stod = $psd - $psdn;
			match $func->($psdn, $stod, @zone), $pdd;
			$func = \&{"Date::MSD::${src}n_to_${dst}n"};
			$dn0 = $func->($psdn, $stod, @zone);
			($dn1, $dtod) = $func->($psdn, $stod, @zone);
			match $dn0, $dn1;
			ok $dtod >= 0 && $dtod < 1;
			match $dn1 + $dtod, $pdd;
		} }
	} }
}

check({
	msd => 46236.625,
	js => 140365.625,
	cmsd => 546236.59375,
}, -0.03125);

check({
	msd => -1000000.25,
	js => -905871.25,
	cmsd => -500000.125,
}, 0.125);

check({
	msd => -300000.25,
	js => -205871.25,
	cmsd => 199999.875,
}, 0.125);

check({
	msd => -300000,
	js => -205871,
	cmsd => 200000.125,
}, 0.125);

1;
