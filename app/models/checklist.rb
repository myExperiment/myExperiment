# myExperiment: app/models/checklist.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class Checklist < ActiveRecord::Base

  belongs_to :research_object

  has_many :checklist_items, :dependent => :destroy

  def to_param
    slug
  end 


  def run_checklist!

    entry = Conf.research_object_checklists[slug]

    query = {
#     "RO"      => "http://alpha2.myexperiment.org/rodl/ROs/Pack15/",
      "RO"      => @pack.research_object.uri.to_s,
      "minim"   => entry["minim"],
      "purpose" => entry["purpose"]
    }

    checklist_uri = "#{entry["service"]}?#{query.to_query}"

#   results = scrape_checklist_results(File.read("checklist2.html"))
    results = scrape_checklist_results(open(checklist_uri))

    update_attributes(
        :score     => results[:score],
        :max_score => results[:max_score])

    checklist_items.delete_all

    results[:sub_results].each do |sr|
      checklist_items.build(:colour => sr[:colour].to_s, :text => sr[:text]).save
    end
  end

private

  # FIXME: This is a stop-gap solution.  Yes, really.

  def scrape_checklist_results(html)

    doc = Nokogiri::HTML(html)

    classes = {
      "trafficlight small fail should" => { :colour => :red,   :score => 0 },
      "trafficlight small fail must"   => { :colour => :amber, :score => 1 },
      "trafficlight small pass"        => { :colour => :green, :score => 2 }
    }

    score     = 0
    max_score = 0

    sub_results = doc.xpath("//tr[@class='sub_result']").map do |tr|
      tds = tr.xpath("td")

      score += classes[tds[1].attributes["class"].to_s][:score]
      max_score += 2

      {
        :text   => tds[2].text,
        :colour => classes[tds[1].attributes["class"].to_s][:colour]
      }
    end

    { :score => score, :max_score => max_score, :sub_results => sub_results }
  end

end
