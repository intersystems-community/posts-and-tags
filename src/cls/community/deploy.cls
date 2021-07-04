/// Deployment class
Class community.deploy
{

ClassMethod Run(NameSpace) As %Status
{
    w "Loading data from GitHub", !
    Set sc = $$$OK
    set $namespace = ""

    set owner = "intersystems-community"
    set repo = "posts-and-tags"

    set ns = $namespace
    set $namespace = "%SYS"
    if ('##class(Security.SSLConfigs).Exists("GitHub")) {
        set prop("Protocols") = 24
        set sc = ##class(Security.SSLConfigs).Create("GitHub", .prop)
    }
    set $namespace = ns

    // Setup request config
    set url = "https://api.github.com/repos/"_owner_"/"_repo_"/releases/latest"
    set request = ##class(%Net.HttpRequest).%New()
    set request.SSLConfiguration = "GitHub"

    // Get asset link
    do request.Get(url)
    set reqData = {}.%FromJSON(request.HttpResponse.Data.Read(99999999))
    set downloadUrl = reqData.assets.%Get(0)."browser_download_url"

    // get asset file
    do request.Get(downloadUrl)
    set fn = "globals.gz"
    set s=##class(%Stream.FileBinary).%New() 
    do s.LinkToFile(fn)
    do s.CopyFrom(request.HttpResponse.Data)
    do s.%Save()
    kill s

    // Load globals
    set s = ##class(%Stream.FileBinaryGzip).%New() 
    do s.LinkToFile(fn)
    do $SYSTEM.OBJ.LoadStream(s)
    kill s

    // Delete temp file
    do ##class(%File).Delete(fn)

    Set sc = ##class(community.post).%BuildIndices()
    Set sc = ##class(community.tag).%BuildIndices()
    Set sc = ##class(community.comment).%BuildIndices()

    Return sc
}

}
