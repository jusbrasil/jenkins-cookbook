jenkins Cookbook
================
[![Build Status](https://secure.travis-ci.org/opscode-cookbooks/jenkins.png?branch=master)](http://travis-ci.org/opscode-cookbooks/jenkins)

Installs and configures Jenkins CI server & node slaves. Resource providers to support automation via jenkins-cli, including job create/update.


Requirements
------------
Chef 0.10.10+ and Ohai 6.10+ for platform_family use.

### Platform:
#### Server (Master) Recipe

* Ubuntu
* RHEL/CentOS

### Node (Slave) Recipe

Agent Flavor:

* `ssh` - Any Unix platform that is running `sshd`.
* `jnlp` - Most Unix platforms.
* `windows` - Windows platforms only. Depends on .NET Framework.


Attributes
----------
### Common Attributes

* `node['jenkins']['mirror']` - Base URL for downloading all code (WAR file and plugins).
* `node['jenkins']['java_home']` - Java install path, used for for cli commands.
* `node['jenkins']['iptables_allow']` - If iptables is enabled, add a rule passing `node['jenkins']['server']['port']`.

### Master/Server related Attributes

* `node['jenkins']['server']['install_method']` - Whether Jenkins is installed from packages or run from a WAR file.
* `node['jenkins']['server']['home']` - Location of `JENKINS_HOME` directory.
* `node['jenkins']['server']['user']` - User the Jenkins server runs as.
* `node['jenkins']['server']['group']` - Jenkins user primary group.
* `node['jenkins']['server']['port']` - TCP port Jenkins server listens on.
* `node['jenkins']['server']['url']` - Base URL of the Jenkins server.
* `node['jenkins']['server']['plugins']` - Download the latest version of plugins in this Array, bypassing update center. The members of the Array can either be strings if the latest version desired OR a Hash of the form
`{'name' => 'git', 'version' => '1.4.0'}` if a specific version is required.
* `node['jenkins']['server']['jvm_options']` - Additional tuning parameters to pass the underlying JVM process.
* `node['jenkins']['http_proxy']['variant']` - use `nginx` or `apache2` to proxy traffic to jenkins backend (`nginx` by default)
* `node['jenkins']['http_proxy']['www_redirect']` - add a redirect rule for 'www.*' URL requests ("disable" by default)
* `node['jenkins']['http_proxy']['listen_ports']` - list of HTTP ports for the HTTP proxy to listen on ([80] by default).
* `node['jenkins']['http_proxy']['host_name']` - primary vhost name for the HTTP proxy to respond to (`node['fqdn']` by default).
* `node['jenkins']['http_proxy']['host_aliases']` - optional list of other host aliases to respond to (empty by default).
* `node['jenkins']['http_proxy']['client_max_body_size']` - max client upload size ("1024m" by default, nginx only).
* `node['jenkins']['http_proxy']['server_auth_method']` - Authentication with the server can be done with cas (using `apache2::mod_auth_cas`), or basic (using `htpasswd`). The default is no authentication.
* `node['jenkins']['http_proxy']['basic_auth_username']` - Username to use for HTTP Basic Authentication.
* `node['jenkins']['http_proxy']['basic_auth_password']` - Password to use with HTTP Basic Authentication.
* `node['jenkins']['http_proxy']['cas_login_url']` - Login url for cas if using cas authentication.
* `node['jenkins']['http_proxy']['cas_validate_url']` - Validation url for cas if using cas authentication.
* `node['jenkins']['http_proxy']['cas_validate_server']` - Whether to validate the server cert. Defaults to off.
* `node['jenkins']['http_proxy']['cas_root_proxy_url']` - If set, sets the url that the cas server redirects to after auth.
* `node['jenkins']['http_proxy']['ssl']['enabled']` - Configures jenkins to use SSL. This cookbook expects you to provide your own certificates. You can tell Jenkins where your certificates with the below attributes.
* `node['jenkins']['http_proxy']['ssl']['cert_path']` - The path to your SSL certificate.
* `node['jenkins']['http_proxy']['ssl']['key_path']` - The path to your SSL key.
* `node['jenkins']['http_proxy']['ssl']['ca_cert_path']` - If set, configures apache to use an intermediate certificate authority. Nginx does not use this attribute and expects any intermediate certificates to be appended in the same file as your SSL certificate.

### Node/Slave related Attributes

* `node['jenkins']['node']['agent_type']` - Type of agent to communicate with this slave/node. Valid values include `jnlp`, `ssh` and `windows`. (default is `jnlp`)
* `node['jenkins']['node']['name']` - Name of the node within Jenkins.
* `node['jenkins']['node']['description']` - Jenkins node description.
* `node['jenkins']['node']['executors']` - Number of node executors.
* `node['jenkins']['node']['home]` - Home directory ("Remote FS root") of the node.
* `node['jenkins']['node']['labels']` - Node labels.
* `node['jenkins']['node']['mode']` - Node usage mode, `normal` or `exclusive` (tied jobs only).
* `node['jenkins']['node']['availability']` - `always` keeps node on-line, `demand` off-lines when idle.
* `node['jenkins']['node']['in_demand_delay']` - number of minutes for which jobs must be waiting in the queue before attempting to launch this slave.
* `node['jenkins']['node']['idle_delay']` - number of minutes that this slave must remain idle before taking it off-line.
* `node['jenkins']['node']['env']` - "Node Properties" -> "Environment Variables".
* `node['jenkins']['node']['user']` - user the slave runs as.
* `node['jenkins']['node']['ssh_host']` - Hostname or IP Jenkins Master should connect to when launching an SSH slave.
* `node['jenkins']['node']['ssh_port']` - SSH port Jenkins Master should connect to when launching a slave.
* `node['jenkins']['node']['ssh_user']` - SSH slave user name (only required if Jenkins server and slave user is different).
* `node['jenkins']['node']['ssh_pass']` - SSH slave password (not required when server is installed via `jenkins::server` recipe).
* `node['jenkins']['node']['ssh_private_key']` - Jenkins Master defaults to: `JENKINS_HOME/.ssh/id_rsa` (created by the `jenkins::server` recipe).
* `node['jenkins']['node']['jvm_options']` - Additional tuning parameters to pass the underlying JVM process.

### Windows Node/Slave related Attributes

* `node['jenkins']['node']['winsw_url']` - The url for the winsw exe to download.

Recipes
-------
### server
Creates all required directories, installs Jenkins and generates an ssh private key and stores the ssh public key in the `node['jenkins']['server']['pubkey']` attribute for use by the node recipes. The installation method is controlled by the `node['jenkins']['server']['install_method']` attribute. The following install methods are supported:

* __package__ - Installs Jenkins from the official jenkins-ci.org packages.
* __war__ - Downloads the latest version of the Jenkins WAR file from http://jenkins-ci. The server process is configured to run as a runit service.

### node
The type of agent that is used to communicate with the slave is determined by the attribute `node['jenkins']['node']['agent_type']`. The following agent types are supported:

* __ssh__ - Creates the user and group for the Jenkins slave to run as and sets `.ssh/authorized_keys` to the `node['jenkins']['server']['pubkey']` attribute. The [jenkins-cli.jar](http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI) is downloaded from the Jenkins server and used to manage the nodes via the [groovy](http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Script+Console) cli command. Jenkins is configured to launch a slave agent on the node using it's [SSH slave plugin](http://wiki.jenkins-ci.org/display/JENKINS/SSH+Slaves+plugin).
* __jnlp__ - Creates the user and group for the Jenkins slave to run as and `/jnlpJars/slave.jar` is downloaded from the Jenkins server. The slave process is configured to run as a runit service.
* __windows__ - Creates the home directory for the node slave and sets `JENKINS_HOME` and `JENKINS_URL` system environment variables. The [winsw](http://weblogs.java.net/blog/2008/09/29/winsw-windows-service-wrapper-less-restrictive-license) Windows service wrapper will be downloaded and installed, along with generating `jenkins-slave.xml` from a template. Jenkins is configured with the node as a [jnlp](http://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds) slave and `/jnlpJars/slave.jar` is downloaded from the Jenkins server. The `jenkinsslave` service will be started the first time the recipe is run or if the service is not running. The 'jenkinsslave' service will be restarted if `/jnlpJars/slave.jar` has changed. The end results is functionally the same
had you chosen the option to [Let Jenkins control this slave as a Windows service](http://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service).

### proxy
Installs a proxy and creates a vhost to route traffic to the installed Jenkins server. The type of HTTP proxy that is installed and configured is determined by the `node['jenkins']['http_proxy']['variant']` attribute. The following HTTP proxy variants are supported:

* __apache2__
* __nginx__


Resource/Provider
-----------------
### jenkins_command
This resource executes arbitrary commands against the [Jenkins CLI](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI), supporting the following actions:

    :execute

Here's an [example list of Jenkins commands](https://gist.github.com/sethvargo/7814182), although these can change with major version releases. For example, to perform a Jenkins safe restart:

```ruby
jenkins_command 'safe-restart'
```

To reload the configuration from disk:

```ruby
jenkins_command 'reload-configuration'
```

To prevent Jenkins from starting any new builds (in preparation for a shutdown):

```ruby
jenkins_command 'quiet-down'
```

**NOTE** You must add your own `not_if`/`only_if` guards to the `jenkins_command` to prevent duplicate commands from executing. Just like Chef's core `execute` resource, the `jenkins_command` resource has no way of being idempotent.

### jenkins_node
This resource can be used to configure nodes as the `node_ssh` and `node_windows` recipes do or "Launch slave via execution of command on the Master":

```ruby
jenkins_node node['fqdn'] do
  description  'My node for things, stuff and whatnot'
  executors    5
  remote_fs    '/var/jenkins'
  launcher     'command'
  command      "ssh -i my_key #{node[:fqdn]} java -jar #{remote_fs}/slave.jar"
  env          'ANT_HOME' => '/usr/local/ant', 'M2_REPO' => '/dev/null'
end
```

### jenkins_job
This resource manages Jenkins jobs, supporting the following actions:

    :create, :delete, :disable, :enable

The resource is fully idempotent and convergent. It also supports whyrun mode.

The `:create` action requires a Jenkins job `config.xml`. This config file must exist on the target node and contain a valid Jenkins job configuration file. Because the Jenkins CLI actually reads and generates it's own copy of this file, **do NOT** write this configuration inside of the Jenkins job. We recommend putting them in a temporary directory:

```ruby
xml = File.join(Chef::Config[:file_cache_path], 'bacon-config.xml')

# You could also use a `cookbook_file` or pure `file` resource to generate
# content at this path.
template xml do
  source 'custom-config.xml.erb'
end

# Create a jenkins job (default action is `:create`)
jenkins_job 'bacon' do
  config xml
end
```

```ruby
jenkins_job 'bacon' do
  action :delete
end
```

You can disable a Jenkins job by specifying the `:disable` option. This will disable an existing job, if and only if that job exists and is enabled. If the job does not exist, an exception is raised.

```ruby
jenkins_job 'bacon' do
  action :disable
end
```

You can enable a Jenkins job by specifying the `:enable` option. This will enable an existing job, if and only if that job exists and is disabled. If the job does not exist, an exception is raised.

```ruby
jenkins_job 'bacon' do
  action :enable
end
```

### jenkins_plugin
This resource manages Jenkins plugins, supporting the following actions:

    :install, :uninstall, :enable, :disable

This uses the Jenkins CLI to install plugins. By default, it does a cold deploy, meaning the plugin is installed while Jenkins is still running. **This LWRP does not install plugin dependencies - you must specify all plugin dependencies or Jenkins may not startup correctly!**

The `:install` action idempotely installs a Jenkins plugin on the current node. The name attribute corresponds to the name of the plugin on the Jenkins Update Center. You can also specify a particular version of the plugin to install. Finally, you can specify a full source URL or local path (on the node) to a plugin.

```ruby
# Install the latest version of the greenballs plugin
jenkins_plugin 'greenballs'

# Install version 1.3 of the greenballs plugin
jenkins_plugin 'greenballs' do
  version '1.3'
end

# Install a plugin from a given hpi (or jpi)
jenkins_plugin 'greenballs' do
  source 'http://updates.jenkins-ci.org/download/plugins/greenballs/1.10/greenballs.hpi'
end
```

The `:uninstall` action removes (uninstalls) a Jenkins plugin idempotently on the current node.

```ruby
jenkins_plugin 'greenballs' do
  action :uninstall
end
```

The `:enable` action enables a plugin. If the plugin is not installed, an exception is raised. If the plugin is already enabled, no action is taken.

```ruby
jenkins_plugin 'greenballs' do
  action :enable
end
```

The `:disable` action disables a plugin. If the plugin is not installed, an exception is raised. If the plugin is already disabled, no action is taken.

```ruby
jenkins_plugin 'greenballs' do
  action :disable
end
```

**NOTE** You may need to restart the Jenkins server after changing a plugin. Because this varies on a case-by-case basis (and because everyone chooses to manage their Jenkins servers differently) this LWRP does **NOT** restart Jenkins for you.

### jenkins_user
This resource manages Jenkins users, supporting the following actions:

    :create, :delete

This uses the Jenkins groovy API to create users.

The `:create` action idempotently creates a Jenkins user on the current node. The id attribute corresponds to the username of the id of the user on the target node. You may also specify a name, email, and list of SSH keys.

```ruby
# Create a Jenkins user
jenkins_user 'grumpy'

# Create a Jenkins user with specific attributes
jenkins_user 'grumpy' do
  full_name    'Grumpy Dwarf'
  email        'grumpy@example.com'
  public_keys  ['ssh-rsa AAAAB3NzaC1y...']
end
```

The `:delete` action removes a Jenkins user from the system.

```ruby
jenkins_user 'grumpy' do
  action :delete
end
```


Caveats
-------
### Authentication
If you use or plan to use authentication for your Jenkins cluster (which we highly recommend), you will need to set a special node attribute:

```ruby
node['jenkins']['cli']['private_key']
```

The underlying executor class (which all LWRPs use) intelligently adds authentication information to the Jenkins CLI commands if this attribute is set. The method used to generate and populate this private key is left to the user:

```ruby
# Using search
master = search(:node, 'fqdn:master.ci.example.com').first
node.set['jenkins']['cli']['private_key'] = master['jenkins']['private_key']

# Using encrypted data bags and chef-sugar
private_key = encrypted_data_bag_item('jenkins', 'keys')['private_key']
node.set['jenkins']['cli']['private_key'] = private_key
```


### Proxies
If you need to pass through a proxy server to communicate between your masters and slaves, you will need to set a special node attribute:

```ruby
node['jenkins']['cli']['proxy']
```

The underlying executor class (which all LWRPs use) intelligently passes proxy information to the Jenkins CLI commands if this attribute is set. It should be set in the form `HOST:PORT`:

```ruby
node.set['jenkins']['cli']['proxy'] = '1.2.3.4:5678'
```


Development
-----------
This section details "quick development" steps. For a detailed explanation, see [[Contributing.md]].

1. Clone this repository from GitHub:

        $ git clone git@github.com:opscode-cookbooks/jenkins.git

2. Create a git branch

        $ git checkout -b my_bug_fix

3. Install dependencies:

        $ bundle install

4. Make your changes/patches/fixes, committing appropiately
5. **Write tests**
6. Run the tests:
    - `bundle exec foodcritic -f any .`
    - `bundle exec rspec`
    - `bundle exec rubocop`
    - `bundle exec kitchen test`

  In detail:
    - Foodcritic will catch any Chef-specific style errors
    - RSpec will run the unit tests
    - Rubocop will check for Ruby-specific style errors
    - Test Kitchen will run and converge the recipes


License & Authors
-----------------
- Author:: Doug MacEachern (<dougm@vmware.com>)
- Contributor:: AJ Christensen <aj@junglist.gen.nz>
- Contributor:: Fletcher Nichol <fnichol@nichol.ca>
- Contributor:: Roman Kamyk <rkj@go2.pl>
- Contributor:: Darko Fabijan <darko@renderedtext.com>
- Contributor:: Seth Chisamore <schisamo@opscode.com>

```text
Copyright (c) 2010 VMware, Inc.
Copyright (c) 2011 Fletcher Nichol
Copyright (c) 2013 Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
