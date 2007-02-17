use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Date::MSD",
	VERSION_FROM => "lib/Date/MSD.pm",
	PREREQ_PM => {
		"Math::BigRat" => "0.04",
	},
);
