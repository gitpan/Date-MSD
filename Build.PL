use warnings;
use strict;
no strict "subs";

use Module::Build;

Module::Build->new(
	module_name => "Date::MSD",
	license => "perl",
	build_requires => {
		Module::Build => 0,
		Test::More => 0,
		perl => "5.006",
		strict => 0,
		warnings => 0,
	},
	requires => {
		Carp => 0,
		Exporter => 0,
		base => 0,
		perl => "5.006",
		strict => 0,
		warnings => 0,
	},
	conflicts => {
		Math::BigRat => "< 0.04",
	},
	dynamic_config => 0,
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

exit 0;
