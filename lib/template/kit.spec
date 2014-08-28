#
# spec file for tetra kit for project "<%= name %>"
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

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           <%= name %>-kit
Version:        <%= version %>
Release:        1
License:        Apache-2.0
Summary:        Build-time dependencies for tetra project <%= name %>
Url:            https://github.com/SilvioMoioli/tetra
Group:          Development/Libraries/Java
Source0:        %{name}.tar.xz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  xz
BuildRequires:  fdupes
Provides:       tetra(kit)
<% binary_packages.each do |binary_package| %>
Provides:       mvn(<%= binary_package.group_id %>:<%= binary_package.artifact_id %>) == <%= binary_package.version %>
<% end %>
# no two kits should ever be installed at any given time
Conflicts:      otherproviders(tetra(kit))

%description
This package has been automatically created by tetra in order to
satisfy build time dependencies of some Java packages. It should
not be used except for rebuilding those packages and it should never
be installed on end users' systems.

%prep
%setup -q -c

%build
# nothing to do, tetra kits are precompiled by design

%install
export NO_BRP_CHECK_BYTECODE_VERSION=true
install -d -m 0755 %{buildroot}%{_datadir}/tetra/%{name}/
cp -a * %{buildroot}%{_datadir}/tetra/%{name}/
%fdupes -s %{buildroot}%{_datadir}/tetra/%{name}/

%files
%defattr(-,root,root)
%{_datadir}/tetra/

%changelog
