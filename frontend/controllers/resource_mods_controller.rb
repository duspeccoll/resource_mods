class ResourceModsController < ApplicationController

	require 'csv'
	require 'zip'
	require 'net/http'

	set_access_control "view_repository" => [:index, :mods]

	def index
	end

	def mods
		resource = params['mods_resource']['ref']
		output = download_mods(resource)
		output.rewind
		send_data output.read, filename: "mods_download.zip"
	end

	private

	def get_request(url)
		req = Net::HTTP::Get.new(url.request_uri)
		req['X-ArchivesSpace-Session'] = Thread.current[:backend_session]
		resp = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
		obj = resp.body if resp.code == "200"
		return obj
	end

	def get_tree(resource)
		url = URI("#{JSONModel::HTTP.backend_url}#{resource}/tree")
		tree = JSON.parse(get_request(url))
		return tree
	end

	def get_mods(url)
		mods = get_request(url)
		return mods
	end

	def process_tree(obj, zos, log)
		url = URI("#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/archival_objects/mods/#{obj['id']}.xml")
		filename = String.new
		if obj['level'] == "item"
			if obj['component_id']
				filename = "#{obj['component_id']}.xml"
			else
				filename = "#{obj['id']}.xml"
			end
			mods = get_mods(url)
			zos.put_next_entry filename
			zos.print mods
			log.push("#{filename} (#{url}) downloaded")
		end
		obj['children'].each do |child|
			process_tree(child, zos, log)
		end
	end

	def download_mods(resource)
		tree = get_tree(resource)
		log = Array.new
		output = Zip::OutputStream.write_buffer do |zos|
			tree['children'].each do |child|
				process_tree(child, zos, log)
			end
			zos.put_next_entry "action_log.txt"
			log.each do |entry|
				zos.puts entry
			end
		end
		return output
	end

end
