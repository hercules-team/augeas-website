#
# Functions used by the templates
#

def is_parent(page, thispage):
    if page == thispage:
        return True
    if page["pages"] is not None:
        for p in page["pages"]:
            if p == thispage:
                return True
    return False

def print_entry(page, active):
    if page['thispage']:
        print "<span class='active'>%(link-title)s</span>" % page
    else:
        if page["target"] == "fh-trac":
            page["target"] = "https://fedorahosted.org/augeas/report/1"
        if active:
            page["aug_cls"] = "active"
        else:
            page["aug_cls"] = "inactive"
        i = page["target"].find("http:")
        if i == -1:
            i = page["target"].find("https:")
        if i != -1:
            page["target"] = page["target"][i:]
        print "<a class='%(aug_cls)s' title='%(link-title)s' href='%(target)s'>%(link-title)s</a>" % page

def menu(thispage, indextree):
    print "<li><div>"
    print_entry(indextree, indextree["thispage"])
    for page in indextree["pages"]:
        expand = is_parent(page, thispage)
        print "<li><div>"
        print_entry(page, expand)
        if expand and page['pages'] is not None:
            print "<ul class='l1'>"
            for page1 in page['pages']:
                print "<li>"
                print_entry(page1, is_parent(page1, thispage))
                print"</li>"
            print "</ul>"
        print "</div></li>"
