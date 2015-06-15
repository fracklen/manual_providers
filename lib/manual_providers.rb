require 'mechanize'
require 'net/http'
require 'json'

class ManualProviders

  class << self
    def profi
      url = "http://old.lokalguiden.se/users/uid/7378/index.php?usr=7378&ord=11&sid=1&setNumPerPage=1000"
      mechanize = Mechanize.new
      page = mechanize.get(url)
      res = []
      page.links.each do |link|
        res << {"href" => link.href, "address" => link.text, "id" => /\d{8}/.match(link.href)[0]} unless link.href.nil?
      end
      res
    end

    def wilfast
      url = "http://www.lokalnytt.se/pages/external.php?type_id=&area_id=&extid=548"
      mechanize = Mechanize.new
      page = mechanize.get(url)
      res = []
      page.links.each_slice(4).to_a.each do |loc|
        id = loc[0].node.attributes["name"].value
        href = "http://www.lokalnytt.se" + loc[1].node.attributes["href"].value
        address = loc[2].node.children[0].text.strip
        res << {"href" => href, "address" => address, "id" => id }
      end
      res
    end

    def tribona
      url = "http://www.objektvision.se/Lists/Standard?key=RgNcrow2S9Y1"
      mechanize = Mechanize.new
      page = mechanize.get(url)
      res = []
      page.links.each_slice(4).to_a.each do |loc|
        href = "http://www.objektvision.se" + loc[0].attributes["href"]
        id = /\d{9}/.match(href)[0]
        address = loc[3].text + ", " + loc[2].text
        res << {"href" => href, "address" => address, "id" => id }
      end
      res
    end

    def svenska_hus
      url = "http://www.svenskahus.se/lediga-lokaler"
      mechanize = Mechanize.new
      page = mechanize.get(url)
      res = []
      page.search("tr").each do |node|
        if node["id"] =~ /tblRwPremise_/
          address = node.children[2].text.strip #=> "Ranhammarsvägen 20"
          type = node.children[3].text.strip #=> "Kontorshotell"
          id = node.children[4].text.strip #=> "2030-1130"
          href = "http://www.svenskahus.se" + node.children[2].children[1]["href"]
          res << {"href" => href, "address" => address, "id" => id }
        end
      end
      res
    end

    def skanska
      kontorlokaler = "http://www.skanska.se/Services/Commercial/LoadProperties.aspx?id=4587&epslanguage=sv&_=1418508712351"
      butikker = "http://www.skanska.se/Services/Commercial/LoadProperties.aspx?id=4582&epslanguage=sv&_=1418508919111"
      lager = "http://www.skanska.se/Services/Commercial/LoadProperties.aspx?id=4581&epslanguage=sv&_=1418509028445"
      virksomheds_lokaler = "http://www.skanska.se/Services/Commercial/LoadProperties.aspx?id=4583&epslanguage=sv&_=1418509070607"
      res = []
      [kontorlokaler, butikker, lager, virksomheds_lokaler].each do |url|
        all = JSON.parse(Net::HTTP.get(URI(url)))
        all.each do |loc|
          address = loc["addressline1"] + ", " + loc["addresspostal"] + " "+ loc["addresscity"]
          id = loc["id"]
          href = loc["url"]
          postnummer_matcher = /.*(\d\d\d)\s(\d\d).*/.match(address)
          if postnummer_matcher
            postcode = postnummer_matcher[1] + postnummer_matcher[2]
            postnummer = postcode.to_i

            if postnummer >= 40010 and postnummer <= 47500
              res << {"href" => href, "address" => address, "id" => id }
            end
          end
        end
      end
      res
    end

    def kungsleden
      res = []
      uri = URI("http://www.kungsleden.se/Services/PremiseSearchService.asmx/Search")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json; charset=UTF-8'})
      req.body = '{ "q":"Skåne", "areaType":"Län", "types":["shop","industry","office","warehouse","other"], "sizes":["Small","Medium","Large"], "language":"sv", "isMapSearch":false, "sortProperty":"address" }'
      body = http.request(req).body
      response = JSON.parse(body)
      doc = Nokogiri::HTML(response["d"]["ListContent"])
      locations = doc.children[1].children[0].children.each_slice(2).to_a

      locations.each do |loc|
        href = loc[0].attributes["href"].text
        address = loc[0].attributes["title"].text
        id = href
        res << {"href" => "http://www.kungsleden.se"+href, "address" => address, "id" => id }
      end
      res
    end

    def areim
      url = "http://www.lokalguiden.se/users/uid/7493/"
       mechanize = Mechanize.new
      page = mechanize.get(url)
      res = []
      page.links.each do |link|
        res << {"href" => link.href, "address" => link.text, "id" => /\d{8}/.match(link.href)[0]} unless link.href.nil?
      end
      res
    end

  end

end
