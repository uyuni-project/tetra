#
# spec file for "<%= name %>"
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

Name:           <%= name %>
Version:        <%= version %>
Release:        1
License:        <%= license %>
Summary:        <%= summary %>
Url:            <%= url %>
Group:          Development/Libraries/Java
Source0:        %{name}.tar.xz
Source1:        build.sh
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  xz
BuildRequires:  java-devel
<% kit_items.each do |item| %>
BuildRequires:  <%= item.provides_symbol %> == <%= item.provides_version %>
<% end %>
BuildArch:      noarch
Provides:       mvn(<%= group_id %>:<%= artifact_id %>) == <%= version %>
Requires:       java
<% runtime_dependency_ids.each do |dependency_id| %>
Requires:       mvn(<%= dependency_id[0] %>:<%= dependency_id[1] %>) <% if dependency_id[3] != nil %>==<%= dependency_id[3] %><% end %>
<% end %>

# to use this package in other tetra builds, uncomment the following
#Provides:       tetra-mvn(<%= group_id %>:<%= artifact_id %>) == <%= version %>

%description
<%=
  description
%>

%prep
%setup -q -c -n src
cp -f %{SOURCE1} .
cp -Rf %{_datadir}/tetra ../kit

%build
cd ..
sh src/build.sh

%install
export NO_BRP_CHECK_BYTECODE_VERSION=true
mkdir -p %{buildroot}%{_javadir}
<% outputs.each do |output| %>
cp -a <%= output %> %{buildroot}%{_javadir}/<%= File.basename(output) %>
<% end %>

# to use this package in other tetra builds, uncomment and edit appropriately
#%define _kitdir %{_datadir}/tetra/m2/<%= group_id.gsub(".", "/") %>/<%= artifact_id %>/<%= version %>
#mkdir -p %_kitdir
<% outputs.each do |output| %>
#ln -s %{buildroot}%{_javadir}/<%= File.basename(output) %> %_kitdir
<% end %>
#ln -s <pomfile> %_kitdir

%files
%defattr(-,root,root)
<% outputs.each do |output| %>
%{_javadir}/<%= File.basename(output) %>
<% end %>

%changelog
