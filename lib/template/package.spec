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
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  coreutils
BuildRequires:  <%= project_name %>-kit
BuildArch:      noarch
Provides:       mvn(<%= group_id %>:<%= artifact_id %>) == <%= version %>
<% runtime_dependency_ids.each do |dependency_id| %>
Requires:       mvn(<%= dependency_id[0] %>:<%= dependency_id[1] %>) <% if dependency_id[3] != nil %>==<%= dependency_id[3] %><% end %>
<% end %>

%description
<%=
  description
%>

%prep
%setup -q -c -n src/<%= name %>
ln -sf %{_datadir}/gjp/<%= project_name %>-kit ../../kit

%build
cd ../../
sh src/<%= name %>/build.sh

%install
mkdir -p %{buildroot}%{_javadir}
<% outputs.each do |output| %>
cp -a <%= output %> %{buildroot}%{_javadir}/<%= File.basename(output) %>
<% end %>

%files
%defattr(-,root,root)
<% outputs.each do |output| %>
%{_javadir}/<%= File.basename(output) %>
<% end %>

%changelog
