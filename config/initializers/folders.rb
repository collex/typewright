# load all the site specific stuff
config_file = File.join(Rails.root, "config", "site.yml")
if File.exists?(config_file)
	site_specific = YAML.load_file(config_file)
	XML_PATH = site_specific['xml']
end
