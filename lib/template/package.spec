#
# spec file for "<%= name %>"
#
# Copyright (c) <%= Time.now.year %> SUSE LLC and contributors
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
Release:        0
License:        <%= license %>
Summary:        <%= summary %>
URL:            <%= url %>
Source0:        <%= src_archive %>
Source1:        build.sh
<% patches.each_with_index do |patch, i| %>
Patch<%= i %>:         <%= patch %>
<% end %>
BuildRequires:  xz
<% if src_archive&.downcase&.end_with?(".zip") %>
BuildRequires:  unzip
<% end %>
BuildRequires:  java-devel
BuildRequires:  <%= kit_name %> == <%= kit_version %>
BuildArch:      noarch
<% artifact_ids.each do |artifact_id| %>
Provides:       mvn(<%= group_id %>:<%= artifact_id %>) == <%= version %>
<% end %>
Requires:       java
<% runtime_dependency_ids.each do |dependency_id| %>
Requires:       mvn(<%= dependency_id[0] %>:<%= dependency_id[1] %>) <% if dependency_id[3] %>== <%= dependency_id[3] %><% end %>
<% end %>

%description
<%= description %>

%prep
%setup -q -c -n src
<% patches.each_with_index do |patch, i| %>
%patch -P <%= i %> -p2
<% end %>
cp -f %{SOURCE1} .
cp -Rf %{_datadir}/tetra ../kit

%build
# Use /bin/bash explicitly to ensure environment consistency
cd ..
/bin/bash src/build.sh

%install
export NO_BRP_CHECK_BYTECODE_VERSION=true
mkdir -p %{buildroot}%{_javadir}
<% outputs.each do |output| %>
cp -a <%= output %> %{buildroot}%{_javadir}/<%= File.basename(output) %>
<% end %>

%files
%defattr(-,root,root)
<% license_files.each do |file| %>
%doc <%= file %>
<% end %>
%{_javadir}/*

%changelog
