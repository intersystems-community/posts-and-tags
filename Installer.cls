Class App.Installer
{

XData setup
{
<Manifest>
  <Default Name="SourceDir" Value="#{$system.Process.CurrentDirectory()}src"/>
  <Default Name="Namespace" Value="IRISAPP"/>
  <Namespace Name="${Namespace}" Create="yes" Code="${Namespace}-CODE" Data="${Namespace}-DATA">
    <Configuration>
      <Database Name="${Namespace}-CODE" Dir="/opt/irisapp/${Namespace}/code" Create="yes" Resource="%DB_${Namespace}"/>
      <Database Name="${Namespace}-DATA" Dir="/opt/irisapp/${Namespace}/data" Create="yes" Resource="%DB_${Namespace}"/>
    </Configuration>
    <Import File="${SourceDir}" Flags="ck" Recurse="1"/>
  </Namespace>
  <RunInstall Class="App.Installer" Method="DefaultNS"/>

  <Invoke Class="App.Installer" Method="LoadFreshData" CheckStatus="1">
    <Arg Value="${Namespace}"/>
  </Invoke>

  <Invoke Class="App.Installer" Method="BuildIndex" CheckStatus="1">
    <Arg Value="${Namespace}"/>
  </Invoke>
</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  #; Let XGL document generate code for this method. 
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

ClassMethod DefaultNS(pVars, pLogLevel, tInstaller) As %Status
{
	Set Namespace = tInstaller.Evaluate("${Namespace}")
	Do tInstaller.PushNS("%SYS")
	For user = "UnknownUser", "Admin", "SuperUser", "_SYSTEM", $username {
		Set tProps("NameSpace") = Namespace
		Set tSC = ##class(Security.Users).Modify(user, .tProps)
	}
	Do tInstaller.PopNS()
	Quit tSC
}

ClassMethod BuildIndex(NameSpace) As %Status
{
  zn NameSpace
  Set tSC = ##class(community.post).%BuildIndices()
  Set tSC = ##class(community.tag).%BuildIndices()
  Set tSC = ##class(community.comment).%BuildIndices()
  Quit tSC
}

/// Loading data from releases
ClassMethod LoadFreshData(NameSpace) As %Status
{
  w "Loading data from GitHub", !
  Set sc = $$$OK
  set $namespace = NameSpace

  set owner = "intersystems-community"
  set repo = "posts-and-tags"
  
  set ns = $namespace
  set $namespace = "%SYS"
  set prop("Protocols") = 24
  set sc = ##class(Security.SSLConfigs).Create("GitHub", .prop)
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

  Return sc
}

}
