#
# spec file for a build-time dependency of project "<%= project.name %>"
#
# Copyright (c) <%= Time.now.year %> <%= Etc.getlogin %>
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

Name:           <%= name %>
Version:        <%= version %>
Release:        1
License:        SUSE-NonFree
Summary:        Build-time dependency of project "<%= project_name %>"
Url:            https://github.com/SilvioMoioli/tetra
Group:          Development/Libraries/Java
Source0:        %{name}.tar.xz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  xz
BuildRequires:  fdupes
Provides:       tetra-kit
Conflicts:      otherproviders(tetra-kit)

%description
This package has been automatically created by tetra in order to
satisfy build time dependencies of Java packages.
It should not be used except for rebuilding other packages,
thus it should never be installed on end users' systems.

%prep
%setup -q -T -D -n .

%build
# nothing to do, precompiled by design

%install
export NO_BRP_CHECK_BYTECODE_VERSION=true
install -d -m 0755 %{buildroot}%{_datadir}/tetra/
tar -C %{buildroot}%{_datadir}/tetra --strip-components=1 -xJf %{S:0}
find %{buildroot} -type f -name *.py -exec sed -i '1s/python\b/python2/' {} \;
%fdupes -s %{buildroot}%{_datadir}/tetra/

%files
%defattr(-,root,root)
%{_datadir}/tetra/

%changelog
