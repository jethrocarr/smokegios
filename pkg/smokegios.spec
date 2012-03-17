Summary: Read Nagios configuration, generate Smokeping configuration files
Name: smokegios
Version: 0.1
Release: 1%{?dist}
License: GPLv3
URL: http://projects.jethrocarr.com/p/oss-smokegios/
Group: Applications/Internet
Source0: smokegios-%{version}.tar.bz2

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch

Requires: perl, perl(Log::Log4perl), perl(Nagios::Config)


%description
Provides an application to read Nagios's configuration files, detect when they
have changed and generate configuration for Smokeping.

This allows easy synchronisation of host & hostgroup information from Nagios
to Smokeping without administrator intervention.


%prep
%setup -q -n smokegios-%{version}

%build

# adjust default config path in executable
sed -i 's|/etc/smokegios/smokegios.conf|/etc/smokeping/smokegios.conf|' bin/smokegios.pl


%install
rm -rf $RPM_BUILD_ROOT

# install binaries
mkdir -p -m0755 $RPM_BUILD_ROOT/%{_bindir}/
install -m0755 bin/smokegios.pl $RPM_BUILD_ROOT/%{_bindir}/smokegios

# install configuration (into the smokeping directory)
mkdir -p -m075 $RPM_BUILD_ROOT/%{_sysconfdir}/smokeping/
install -m0644 etc/smokegios.conf $RPM_BUILD_ROOT/%{_sysconfdir}/smokeping/smokegios.conf

# install cronfile
mkdir -p $RPM_BUILD_ROOT/etc/cron.d/
install -m0644 pkg/smokegios.cron $RPM_BUILD_ROOT/%{_sysconfdir}/cron.d/smokegios

# install logrotate configuration
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/logrotate.d/
install -m0644 pkg/smokegios.logrotate.conf $RPM_BUILD_ROOT%{_sysconfdir}/logrotate.d/smokegios


%post

# first time installation?
if [ $1 == 1 ];
then
	echo ""
	echo "IMPORTANT: You must configure smokeping to include smokegios configuration, add the following to *** Targets *** section:"
	echo "### Smokegios Start ###"
	echo "### Smokegios End ###"
	echo "All data between this header & footer will be automatically generated."
	echo ""
	echo "Smokegios will run on an hourly basis by default"
	echo ""
else
	echo "Executing Smokegios post-upgrade..."
	%{_bindir}/smokegios -c %{_sysconfdir}/smokeping/smokegios.conf
fi


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc doc/README doc/AUTHORS doc/COPYING
%config %dir %{_sysconfdir}/smokeping
%config(noreplace) %{_sysconfdir}/smokeping/smokegios.conf
%config(noreplace) %{_sysconfdir}/cron.d/smokegios
%config(noreplace) %{_sysconfdir}/logrotate.d/smokegios
%{_bindir}/smokegios



%changelog
* Mon May 30 2011 Jethro Carr <jethro.carr@amberdms.com> 0.1-1
- Very first version & package release

