node.default['java']['jdk_version'] = 7
node.default['java']['install_flavor'] = "openjdk"
include_recipe "java"

kagent_bouncycastle "jar" do
end

group node[:hadoop][:group] do
  action :create
end

user node[:hadoop][:user] do
  supports :manage_home => true
  action :create
  home "/home/#{node[:hadoop][:user]}"
  system true
  shell "/bin/bash"
end

group node[:hadoop][:group] do
  action :modify
  members node[:hadoop][:user]
  append true
end


directory node[:hadoop][:dir] do
  owner node[:hadoop][:user]
  group node[:hadoop][:group]
  mode "0755"
  recursive true
  action :create
end

case node[:platform_family]
when "debian"
package "openssh-server" do
 action :install
 options "--force-yes"
end

package "openssh-client" do
 action :install
 options "--force-yes"
end
when "rhel"

end

package_url = node[:hadoop][:download_url]
Chef::Log.info "Downloading hadoop binaries from #{package_url}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config[:file_cache_path]}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner node[:hadoop][:user]
  group node[:hadoop][:group]
  mode "0755"
  # TODO - checksum
  action :create_if_missing
end

base_name = File.basename(base_package_filename, ".tgz")
# Extract and install hadoop
bash 'extract-hadoop' do
  user "root"
  code <<-EOH
        rm -rf #{node[:hadoop][:dir]}/hadoop
	tar -xf #{cached_package_filename} -C #{node[:hadoop][:dir]}
        mv #{node[:hadoop][:dir]}/hadoop #{node[:hadoop][:home]}
# chown -L : traverse symbolic links
        ln -s #{node[:hadoop][:home]} #{node[:hadoop][:dir]}/hadoop
        chown -RL #{node[:hadoop][:user]}:#{node[:hadoop][:group]} #{node[:hadoop][:home]}
        touch #{node[:hadoop][:home]}/.downloaded
	EOH
  not_if { ::File.exist?("#{node[:hadoop][:home]}/.downloaded") }
end

 directory node[:hadoop][:logs_dir] do
   owner node[:hadoop][:user]
   group node[:hadoop][:group]
   mode "0755"
   action :create
 end

 directory node[:hadoop][:tmp_dir] do
   owner node[:hadoop][:user]
   group node[:hadoop][:group]
   mode "0755"
   action :create
 end

include_recipe "hops"