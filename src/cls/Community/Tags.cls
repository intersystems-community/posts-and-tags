Class Community.Tags Extends %Persistent
{

Property Name As %String(MAXLEN = "");

Index NameIdx On Name [ IdKey, Unique ];

Property Description As %String(MAXLEN = "");

Storage Default
{
<Data name="TagsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^Community.TagsD</DataLocation>
<DefaultData>TagsDefaultData</DefaultData>
<IdLocation>^Community.TagsD</IdLocation>
<IndexLocation>^Community.TagsI</IndexLocation>
<StreamLocation>^Community.TagsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
