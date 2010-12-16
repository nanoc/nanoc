# A nanoc filter that decorates a plain-text tweet with links and some CSS styling
class TwitterFilter < Nanoc3::Filter
  # The identifier to use in the Rules file
  identifier :twitter
  
  # We can haz only text.
  type :text
  
  # Takes a plain-text tweet and adds links to URL fragments and users on twitter
  #
  # Options can be passed as a hash to give a CSS class to the 'a' tag (:link_class),
  # as well as whether the link should open in a new window/tab (:new_window). Also,
  # options can also be given to linkify twitter users in tweets (:linkify_users).
  #
  # @param [String] Content to be filteres
  #
  # @return [String] The filtered content
  def run(content, params = { :link_class => '', :new_window => true, :linkify_users => true })
    params[:link_class].nil? ? link_class = '' : link_class = " class=\"#{params[:link_class].strip}\""
    params[:new_window].is_a?(TrueClass) ? new_window = ' target="_new"' : ''
    linked_content = content.gsub(/(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/) { |x| true ? "<a href='#{x}'#{link_class}#{new_window}>#{x}</a>" : x } 

    if params[:linkify_users]
      return linked_content.gsub(/@([a-z0-9_]+)/i) { |user| user.delete!('@'); "@<a href=\"http://twitter.com/#{user}\">#{user}</a>"}
    end
    
    return linked_content
  end
end