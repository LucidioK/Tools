$global:AzureDevOpsUrlBase = 'https://dev.azure.com';
$global:AzureDevOpsUrlBasePF = "$($global:AzureDevOpsUrlBase)/LK";
$global:AzureDevOpsUrlBasePFPF = "$($global:AzureDevOpsUrlBase)/LK/LK";

if ($env:AzureDevOpsPersonalToken -eq $null)
{
    write-host "`n`n`n";
    throw "Please set the AzureDevOpsPersonalToken environment variable with the token from https://LK.visualstudio.com/_usersSettings/tokens";
}

<#
.SYNOPSIS
  Creates the header with Authorization item built from the AzureDevOpsPersonalToken environment variable, which must be have token from https://LK.visualstudio.com/_usersSettings/tokens.
.DESCRIPTION
  Creates the header with Authorization item built from the AzureDevOpsPersonalToken environment variable, which must be have token from https://LK.visualstudio.com/_usersSettings/tokens.

.OUTPUTS
  A dictionary with the authorization header.
  
.EXAMPLE
    AzureDevOps-AuthorizationHeader | ConvertTo-Json
    {
        "Authorization":  "Basic BASE64_REPRESENTATION_OF_LK_AS_USERNAME_AND_AzureDevOpsPersonalToken_AS_PASSWORD"
    }


#>
function global:AzureDevOps-AuthorizationHeader()
{
    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "LK",$env:AzureDevOpsPersonalToken)))
    return @{ Authorization = "Basic $basicAuth" }
}

<#
.SYNOPSIS
  Runs a REST GET against a full Azure DevOps URL, automatically injecting the Authorization Header from AzureDevOps-AuthorizationHeader.
.DESCRIPTION
  Runs a REST GET against a full Azure DevOps URL, automatically injecting the Authorization Header from AzureDevOps-AuthorizationHeader.

.PARAMETER <url>
    The URL to be executed.

.OUTPUTS
  The object retrieved by the REST GET.
  
.EXAMPLE
    AzureDevOps-Get 'https://dev.azure.com/LK/LK/_apis/wit/workitems?ids=23916&api-version=5.0' 
    count value                                                                                                                           
    ----- -----                                                                                                                           
        1 {@{id=23916; rev=11; fields=; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916}}

#>
function global:AzureDevOps-Get([string]$url)
{
    Invoke-RestMethod -Method Get -Headers (AzureDevOps-AuthorizationHeader) -Uri $url;
}

<#
.SYNOPSIS
  Retrieves data from one work item, by item ID.
.DESCRIPTION
  Retrieves data from one work item, by item ID.

.PARAMETER <id>
    ID of item to be retrieved.

.OUTPUTS
  An object with all fields from the work item.
  
.EXAMPLE
    AzureDevOps-GetWorkItem 23916 | convertto-json -Depth 16 
    {
        "id":  23916,
        "rev":  11,
        "fields":  {
                       "System.Id":  23916,
                       "System.AreaId":  47,
                       "System.AreaPath":  "LK\\Developer Services",
                       "System.TeamProject":  "LK",
                       "System.NodeName":  "Developer Services",
                       "System.AreaLevel1":  "LK",
                       "System.AreaLevel2":  "Developer Services",
                       "System.Rev":  11,
                       "System.AuthorizedDate":  "2019-05-23T23:52:33.623Z",
                       "System.RevisedDate":  "9999-01-01T00:00:00Z",
                       "System.IterationId":  138,
                       "System.IterationPath":  "LK\\2019\\1906\\Sprint 12 (Ends 6-14)",
                       "System.IterationLevel1":  "LK",
                       "System.IterationLevel2":  "2019",
                       "System.IterationLevel3":  "1906",
                       "System.IterationLevel4":  "Sprint 12 (Ends 6-14)",
                       "System.WorkItemType":  "User Story",
                       "System.State":  "Backlog",
                       "System.Reason":  "Moved to state Backlog",
                       "System.AssignedTo":  {
                                                 "displayName":  "Martin Gudgin",
                                                 "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                 "_links":  {
                                                                "avatar":  {
                                                                               "href":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID"
                                                                           }
                                                            },
                                                 "id":  "SOME_GUID",
                                                 "uniqueName":  "mgudgin@microsoft.com",
                                                 "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                 "descriptor":  "aad.SOME_ID"
                                             },
                       "System.CreatedDate":  "2019-01-27T21:38:49.9Z",
                       "System.CreatedBy":  {
                                                "displayName":  "Martin Gudgin",
                                                "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                "_links":  {
                                                               "avatar":  {
                                                                              "href":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID"
                                                                          }
                                                           },
                                                "id":  "SOME_GUID",
                                                "uniqueName":  "mgudgin@microsoft.com",
                                                "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                "descriptor":  "aad.SOME_ID"
                                            },
                       "System.ChangedDate":  "2019-05-23T23:52:33.623Z",
                       "System.ChangedBy":  {
                                                "displayName":  "Lucidio Kuhn",
                                                "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                "_links":  {
                                                               "avatar":  {
                                                                              "href":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID"
                                                                          }
                                                           },
                                                "id":  "SOME_GUID",
                                                "uniqueName":  "lumayerk@microsoft.com",
                                                "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                "descriptor":  "aad.SOME_ID"
                                            },
                       "System.AuthorizedAs":  {
                                                   "displayName":  "Lucidio Kuhn",
                                                   "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                   "_links":  {
                                                                  "avatar":  {
                                                                                 "href":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID"
                                                                             }
                                                              },
                                                   "id":  "SOME_GUID",
                                                   "uniqueName":  "lumayerk@microsoft.com",
                                                   "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                   "descriptor":  "aad.SOME_ID"
                                               },
                       "System.PersonId":  95655109,
                       "System.Watermark":  97317,
                       "System.CommentCount":  0,
                       "System.Title":  "CS2AF PRIV 0901 PlayStream API: Implement Action Processor",
                       "System.BoardColumn":  "Backlog",
                       "System.BoardColumnDone":  false,
                       "Microsoft.VSTS.Common.StateChangeDate":  "2019-01-27T21:38:49.9Z",
                       "Microsoft.VSTS.Common.Priority":  2,
                       "Microsoft.VSTS.Common.ValueArea":  "Business",
                       "LK.PMOwner":  {
                                               "displayName":  "Sarah Michael",
                                               "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                               "_links":  {
                                                              "avatar":  {
                                                                             "href":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID"
                                                                         }
                                                          },
                                               "id":  "SOME_GUID",
                                               "uniqueName":  "smichael@microsoft.com",
                                               "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                               "descriptor":  "aad.SOME_ID"
                                           },
                       "WEF_B1279FEF64614C6BB43A9E85B0CD2834_System.ExtensionMarker":  true,
                       "WEF_B1279FEF64614C6BB43A9E85B0CD2834_Kanban.Column":  "Backlog",
                       "WEF_B1279FEF64614C6BB43A9E85B0CD2834_Kanban.Column.Done":  false,
                       "WEF_A720E604DE684AF99AD4A189041A0FFD_System.ExtensionMarker":  true,
                       "WEF_A720E604DE684AF99AD4A189041A0FFD_Kanban.Column":  "Backlog",
                       "WEF_A720E604DE684AF99AD4A189041A0FFD_Kanban.Column.Done":  false,
                       "Custom.TriagePF":  "Pending",
                       "Custom.TaskResolvedReasonPF":  "Backlog",
                       "System.Description":  "\u003cdiv\u003eImplement an Action processor for invoking Azure Function based CloudScript when a PlayStream event occurs.\u003c/div\u003e",
                       "System.Tags":  "CS2AF; DevServices; PrivatePreview"
                   },
        "relations":  [
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Reverse",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23915",
                              "attributes":  {
                                                 "isLocked":  false,
                                                 "name":  "Parent"
                                             }
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23921",
                              "attributes":  {
                                                 "isLocked":  false,
                                                 "name":  "Child"
                                             }
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/31199",
                              "attributes":  {
                                                 "isLocked":  false,
                                                 "name":  "Child"
                                             }
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23923",
                              "attributes":  {
                                                 "isLocked":  false,
                                                 "name":  "Child"
                                             }
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23922",
                              "attributes":  {
                                                 "isLocked":  false,
                                                 "name":  "Child"
                                             }
                          }
                      ],
        "_links":  {
                       "self":  {
                                    "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916"
                                },
                       "workItemUpdates":  {
                                               "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/updates"
                                           },
                       "workItemRevisions":  {
                                                 "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/revisions"
                                             },
                       "workItemComments":  {
                                                "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/comments"
                                            },
                       "html":  {
                                    "href":  "https://dev.azure.com/LK/SOME_GUID/_workitems/edit/23916"
                                },
                       "workItemType":  {
                                            "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/User%20Story"
                                        },
                       "fields":  {
                                      "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields"
                                  }
                   },
        "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916"
    }

#>
function global:AzureDevOps-GetWorkItem([int]$id)
{
    $wi     = AzureDevOps-Get "$global:AzureDevOpsUrlBasePFPF/_apis/wit/workitems?ids=$id&api-version=5.0";
    $rs     = AzureDevOps-Get ($wi.value[0].url + '?$expand=All');
    return $rs;
}

<#
.SYNOPSIS
  Retrieves data from all fields from Work Items.
.DESCRIPTION
  Retrieves data from all fields from Work Items.

.OUTPUTS
  A list of objects with full description of every field.
  
.EXAMPLE
    AzureDevOps-GetFields | ConvertTo-Json -Depth 16
    [
        {
            "name":  "Acceptance Criteria",
            "referenceName":  "Microsoft.VSTS.Common.AcceptanceCriteria",
            "description":  null,
            "type":  "html",
            "usage":  "workItem",
            "readOnly":  false,
            "canSortBy":  false,
            "isQueryable":  true,
            "supportedOperations":  [
                                        {
                                            "referenceName":  "SupportedOperations.ContainsWords",
                                            "name":  "Contains Words"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.NotContainsWords",
                                            "name":  "Does Not Contain Words"
                                        }
                                    ],
            "isIdentity":  false,
            "isPicklist":  false,
            "isPicklistSuggested":  false,
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields/Microsoft.VSTS.Common.AcceptanceCriteria"
        },
        {
            "name":  "Accepted By",
            "referenceName":  "Microsoft.VSTS.CodeReview.AcceptedBy",
            "description":  null,
            "type":  "string",
            "usage":  "workItem",
            "readOnly":  false,
            "canSortBy":  true,
            "isQueryable":  true,
            "supportedOperations":  [
                                        {
                                            "referenceName":  "SupportedOperations.Equals",
                                            "name":  "="
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.NotEquals",
                                            "name":  "\u003c\u003e"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.GreaterThan",
                                            "name":  "\u003e"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.LessThan",
                                            "name":  "\u003c"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.GreaterThanEquals",
                                            "name":  "\u003e="
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.LessThanEquals",
                                            "name":  "\u003c="
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.Contains",
                                            "name":  "Contains"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.NotContains",
                                            "name":  "Does Not Contain"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.In",
                                            "name":  "In"
                                        },
                                        {
                                            "name":  "Not In"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.InGroup",
                                            "name":  "In Group"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.NotInGroup",
                                            "name":  "Not In Group"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.Ever",
                                            "name":  "Was Ever"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.EqualsField",
                                            "name":  "= [Field]"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.NotEqualsField",
                                            "name":  "\u003c\u003e [Field]"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.GreaterThanField",
                                            "name":  "\u003e [Field]"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.LessThanField",
                                            "name":  "\u003c [Field]"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.GreaterThanEqualsField",
                                            "name":  "\u003e= [Field]"
                                        },
                                        {
                                            "referenceName":  "SupportedOperations.LessThanEqualsField",
                                            "name":  "\u003c= [Field]"
                                        }
                                    ],
            "isIdentity":  true,
            "isPicklist":  false,
            "isPicklistSuggested":  false,
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields/Microsoft.VSTS.CodeReview.AcceptedBy"
        },
        . . .
#>
function global:AzureDevOps-GetFields()
{
    $fields = AzureDevOps-Get "$global:AzureDevOpsUrlBasePFPF/_apis/wit/fields?$$expand=extensionFields&api-version=5.0";
    $fr = @();
    foreach ($field in $fields.value)
    {
        $fieldData = AzureDevOps-Get $field.url;
        $fr       += $fieldData;
    }
    return $fr;
}

<#
.SYNOPSIS
  Retrieves all work items that contain a given tag.
.DESCRIPTION
  Retrieves all work items that contain a given tag.

.PARAMETER <tag>
    Tag that identifies items to be retrieved.
.OUTPUTS
  A list of objects, each object wit all fields from all work items that contain a given tag.
  
.EXAMPLE
    AzureDevOps-GetWorkItemsByTagValue 'CS2AF' | select -First 2 | ConvertTo-Json 
    [
        {
            "id":  21959,
            "rev":  11,
            "fields":  {
                           "System.Id":  21959,
                           "System.AreaId":  47,
                           "System.AreaPath":  "LK\\Developer Services",
                           "System.TeamProject":  "LK",
                           "System.NodeName":  "Developer Services",
                           "System.AreaLevel1":  "LK",
                           "System.AreaLevel2":  "Developer Services",
                           "System.Rev":  11,
                           "System.AuthorizedDate":  "2019-05-09T18:17:02.63Z",
                           "System.RevisedDate":  "9999-01-01T00:00:00Z",
                           "System.IterationId":  76,
                           "System.IterationPath":  "LK\\2019\\1903",
                           "System.IterationLevel1":  "LK",
                           "System.IterationLevel2":  "2019",
                           "System.IterationLevel3":  "1903",
                           "System.WorkItemType":  "Epic",
                           "System.State":  "Active",
                           "System.Reason":  "Implementation started",
                           "System.AssignedTo":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832
    fc19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1
    OTI4ZWUwNDk4}",
                           "System.CreatedDate":  "2018-12-10T15:33:11.217Z",
                           "System.CreatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.ChangedDate":  "2019-05-09T18:17:02.63Z",
                           "System.ChangedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.AuthorizedAs":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07ef
    f64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWF
    lMDdlZmY2NGFm}",
                           "System.PersonId":  95655109,
                           "System.Watermark":  93087,
                           "System.CommentCount":  1,
                           "System.Title":  "CS2AF CloudScript with CSharp on Azure Functions",
                           "System.BoardColumn":  "Active",
                           "System.BoardColumnDone":  false,
                           "Microsoft.VSTS.Common.StateChangeDate":  "2019-04-05T20:41:57.327Z",
                           "Microsoft.VSTS.Common.ActivatedDate":  "2019-04-05T20:41:57.327Z",
                           "Microsoft.VSTS.Common.ActivatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650
    e-8c06-eae07eff64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03N
    TBlLThjMDYtZWFlMDdlZmY2NGFm}",
                           "Microsoft.VSTS.Common.ResolvedReason":  "Unresolved",
                           "Microsoft.VSTS.Common.Priority":  2,
                           "Microsoft.VSTS.Common.ValueArea":  "Business",
                           "LK.PMOwner":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832fc
    19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1OT
    I4ZWUwNDk4}",
                           "LK.Release":  "FY19-Q4",
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_System.ExtensionMarker":  true,
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_Kanban.Column":  "Active",
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_Kanban.Column.Done":  false,
                           "WEF_830E27F722564306A13AE9FA2DC6206E_System.ExtensionMarker":  true,
                           "WEF_830E27F722564306A13AE9FA2DC6206E_Kanban.Column":  "Active",
                           "WEF_830E27F722564306A13AE9FA2DC6206E_Kanban.Column.Done":  false,
                           "Custom.TaskResolvedReasonPF":  "Unresolved",
                           "System.Tags":  "CS2AF; DevServices"
                       },
            "relations":  [
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21973; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21962; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21972; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22314; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21971; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23915; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22325; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22033; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/27209; attributes=}"
                          ],
            "_links":  {
                           "self":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959}",
                           "workItemUpdates":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/updates}",
                           "workItemRevisions":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/revisions}",
                           "workItemComments":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/comments}",
                           "html":  "@{href=https://dev.azure.com/LK/SOME_GUID/_workitems/edit/21959}",
                           "workItemType":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/Epic}",
                           "fields":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields}"
                       },
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959"
        },
        {
            "id":  21961,
            "rev":  11,
            "fields":  {
                           "System.Id":  21961,
                           "System.AreaId":  47,
                           "System.AreaPath":  "LK\\Developer Services",
                           "System.TeamProject":  "LK",
                           "System.NodeName":  "Developer Services",
                           "System.AreaLevel1":  "LK",
                           "System.AreaLevel2":  "Developer Services",
                           "System.Rev":  11,
                           "System.AuthorizedDate":  "2019-05-23T23:55:31.06Z",
                           "System.RevisedDate":  "9999-01-01T00:00:00Z",
                           "System.IterationId":  135,
                           "System.IterationPath":  "LK\\2019\\1905\\Sprint 9 (Ends 5-3)",
                           "System.IterationLevel1":  "LK",
                           "System.IterationLevel2":  "2019",
                           "System.IterationLevel3":  "1905",
                           "System.IterationLevel4":  "Sprint 9 (Ends 5-3)",
                           "System.WorkItemType":  "Feature",
                           "System.State":  "Active",
                           "System.Reason":  "Implementation started",
                           "System.AssignedTo":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832
    fc19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1
    OTI4ZWUwNDk4}",
                           "System.CreatedDate":  "2018-12-10T16:11:29.803Z",
                           "System.CreatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.ChangedDate":  "2019-05-23T23:55:31.06Z",
                           "System.ChangedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.AuthorizedAs":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07ef
    f64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWF
    lMDdlZmY2NGFm}",
                           "System.PersonId":  95655109,
                           "System.Watermark":  97330,
                           "System.CommentCount":  0,
                           "System.Title":  "CS2AF 01 Updated SDK",
                           "System.BoardColumn":  "Active",
                           "System.BoardColumnDone":  false,
                           "Microsoft.VSTS.Common.StateChangeDate":  "2019-04-05T20:39:23.027Z",
                           "Microsoft.VSTS.Common.ActivatedDate":  "2019-04-05T20:39:23.027Z",
                           "Microsoft.VSTS.Common.ActivatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650
    e-8c06-eae07eff64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03N
    TBlLThjMDYtZWFlMDdlZmY2NGFm}",
                           "Microsoft.VSTS.Common.ResolvedReason":  "Unresolved",
                           "Microsoft.VSTS.Common.Priority":  1,
                           "Microsoft.VSTS.Common.StackRank":  1999992757.0,
                           "Microsoft.VSTS.Common.ValueArea":  "Business",
                           "LK.PMOwner":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832fc
    19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1OT
    I4ZWUwNDk4}",
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_System.ExtensionMarker":  true,
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_Kanban.Column":  "Active",
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_Kanban.Column.Done":  false,
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_System.ExtensionMarker":  true,
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_Kanban.Column":  "Active",
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_Kanban.Column.Done":  false,
                           "LK.Release":  "FY19-Q4",
                           "Custom.FeatureResolvedReasonPF":  "Unresolved",
                           "WEF_2904036E386A4928B52E5043CF160C8E_System.ExtensionMarker":  false,
                           "WEF_2904036E386A4928B52E5043CF160C8E_Kanban.Column":  "New",
                           "WEF_2904036E386A4928B52E5043CF160C8E_Kanban.Column.Done":  false,
                           "System.Tags":  "CS2AF; DevServices"
                       },
            "relations":  [
                              "@{rel=System.LinkTypes.Hierarchy-Reverse; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21966; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21964; attributes=}"
                          ],
            "_links":  {
                           "self":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961}",
                           "workItemUpdates":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/updates}",
                           "workItemRevisions":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/revisions}",
                           "workItemComments":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/comments}",
                           "html":  "@{href=https://dev.azure.com/LK/SOME_GUID/_workitems/edit/21961}",
                           "workItemType":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/Feature}",
                           "fields":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields}"
                       },
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961"
        }
    ]    
#>
function global:AzureDevOps-GetWorkItemsByTagValue([string]$tag)
{
    return (AzureDevOps-GetWorkItemsByQuery "select * From WorkItems Where [Tags] Contains '$tag'");
}

<#
.SYNOPSIS
  Retrieves work items according to a WIQL query.
  WIQL syntax is described here: https://docs.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax?view=azure-devops
  There is even a WIQL query editor to try queries: https://marketplace.visualstudio.com/items?itemName=ottostreifel.wiql-editor
.DESCRIPTION
  Retrieves all work items that contain a given tag.
  WIQL syntax is described here: https://docs.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax?view=azure-devops
  There is even a WIQL query editor to try queries: https://marketplace.visualstudio.com/items?itemName=ottostreifel.wiql-editor

.PARAMETER <query>
    Tag that identifies items to be retrieved.

.OUTPUTS
  A list of objects, each object with all fields from all work items from the query.
  Notice that the query will always return all fields, even if you have specified to retrieve only some fields at the query.
  
.EXAMPLE
    AzureDevOps-GetWorkItemsByQuery "select [System.Id],[System.Title] From WorkItems Where [Tags] Contains 'CS2AF' and [LK.Release] = 'FY19-Q4'" | select -First 2 | ConvertTo-Json 
    [
        {
            "id":  21959,
            "rev":  11,
            "fields":  {
                           "System.Id":  21959,
                           "System.AreaId":  47,
                           "System.AreaPath":  "LK\\Developer Services",
                           "System.TeamProject":  "LK",
                           "System.NodeName":  "Developer Services",
                           "System.AreaLevel1":  "LK",
                           "System.AreaLevel2":  "Developer Services",
                           "System.Rev":  11,
                           "System.AuthorizedDate":  "2019-05-09T18:17:02.63Z",
                           "System.RevisedDate":  "9999-01-01T00:00:00Z",
                           "System.IterationId":  76,
                           "System.IterationPath":  "LK\\2019\\1903",
                           "System.IterationLevel1":  "LK",
                           "System.IterationLevel2":  "2019",
                           "System.IterationLevel3":  "1903",
                           "System.WorkItemType":  "Epic",
                           "System.State":  "Active",
                           "System.Reason":  "Implementation started",
                           "System.AssignedTo":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832
    fc19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1
    OTI4ZWUwNDk4}",
                           "System.CreatedDate":  "2018-12-10T15:33:11.217Z",
                           "System.CreatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.ChangedDate":  "2019-05-09T18:17:02.63Z",
                           "System.ChangedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.AuthorizedAs":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07ef
    f64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWF
    lMDdlZmY2NGFm}",
                           "System.PersonId":  95655109,
                           "System.Watermark":  93087,
                           "System.CommentCount":  1,
                           "System.Title":  "CS2AF CloudScript with CSharp on Azure Functions",
                           "System.BoardColumn":  "Active",
                           "System.BoardColumnDone":  false,
                           "Microsoft.VSTS.Common.StateChangeDate":  "2019-04-05T20:41:57.327Z",
                           "Microsoft.VSTS.Common.ActivatedDate":  "2019-04-05T20:41:57.327Z",
                           "Microsoft.VSTS.Common.ActivatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650
    e-8c06-eae07eff64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03N
    TBlLThjMDYtZWFlMDdlZmY2NGFm}",
                           "Microsoft.VSTS.Common.ResolvedReason":  "Unresolved",
                           "Microsoft.VSTS.Common.Priority":  2,
                           "Microsoft.VSTS.Common.ValueArea":  "Business",
                           "LK.PMOwner":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832fc
    19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1OT
    I4ZWUwNDk4}",
                           "LK.Release":  "FY19-Q4",
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_System.ExtensionMarker":  true,
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_Kanban.Column":  "Active",
                           "WEF_C54A660AB64841DC9CBD25FA36CBAF31_Kanban.Column.Done":  false,
                           "WEF_830E27F722564306A13AE9FA2DC6206E_System.ExtensionMarker":  true,
                           "WEF_830E27F722564306A13AE9FA2DC6206E_Kanban.Column":  "Active",
                           "WEF_830E27F722564306A13AE9FA2DC6206E_Kanban.Column.Done":  false,
                           "Custom.TaskResolvedReasonPF":  "Unresolved",
                           "System.Tags":  "CS2AF; DevServices"
                       },
            "relations":  [
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21973; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21962; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21972; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22314; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21971; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23915; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22325; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/22033; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/27209; attributes=}"
                          ],
            "_links":  {
                           "self":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959}",
                           "workItemUpdates":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/updates}",
                           "workItemRevisions":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/revisions}",
                           "workItemComments":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959/comments}",
                           "html":  "@{href=https://dev.azure.com/LK/SOME_GUID/_workitems/edit/21959}",
                           "workItemType":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/Epic}",
                           "fields":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields}"
                       },
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959"
        },
        {
            "id":  21961,
            "rev":  11,
            "fields":  {
                           "System.Id":  21961,
                           "System.AreaId":  47,
                           "System.AreaPath":  "LK\\Developer Services",
                           "System.TeamProject":  "LK",
                           "System.NodeName":  "Developer Services",
                           "System.AreaLevel1":  "LK",
                           "System.AreaLevel2":  "Developer Services",
                           "System.Rev":  11,
                           "System.AuthorizedDate":  "2019-05-23T23:55:31.06Z",
                           "System.RevisedDate":  "9999-01-01T00:00:00Z",
                           "System.IterationId":  135,
                           "System.IterationPath":  "LK\\2019\\1905\\Sprint 9 (Ends 5-3)",
                           "System.IterationLevel1":  "LK",
                           "System.IterationLevel2":  "2019",
                           "System.IterationLevel3":  "1905",
                           "System.IterationLevel4":  "Sprint 9 (Ends 5-3)",
                           "System.WorkItemType":  "Feature",
                           "System.State":  "Active",
                           "System.Reason":  "Implementation started",
                           "System.AssignedTo":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832
    fc19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1
    OTI4ZWUwNDk4}",
                           "System.CreatedDate":  "2018-12-10T16:11:29.803Z",
                           "System.CreatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.ChangedDate":  "2019-05-23T23:55:31.06Z",
                           "System.ChangedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07eff64
    af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWFlMD
    dlZmY2NGFm}",
                           "System.AuthorizedAs":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650e-8c06-eae07ef
    f64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03NTBlLThjMDYtZWF
    lMDdlZmY2NGFm}",
                           "System.PersonId":  95655109,
                           "System.Watermark":  97330,
                           "System.CommentCount":  0,
                           "System.Title":  "CS2AF 01 Updated SDK",
                           "System.BoardColumn":  "Active",
                           "System.BoardColumnDone":  false,
                           "Microsoft.VSTS.Common.StateChangeDate":  "2019-04-05T20:39:23.027Z",
                           "Microsoft.VSTS.Common.ActivatedDate":  "2019-04-05T20:39:23.027Z",
                           "Microsoft.VSTS.Common.ActivatedBy":  "@{displayName=Lucidio Kuhn; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=66d3f6fa-40f4-650
    e-8c06-eae07eff64af; uniqueName=lumayerk@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.NjZkM2Y2ZmEtNDBmNC03N
    TBlLThjMDYtZWFlMDdlZmY2NGFm}",
                           "Microsoft.VSTS.Common.ResolvedReason":  "Unresolved",
                           "Microsoft.VSTS.Common.Priority":  1,
                           "Microsoft.VSTS.Common.StackRank":  1999992757.0,
                           "Microsoft.VSTS.Common.ValueArea":  "Business",
                           "LK.PMOwner":  "@{displayName=Sarah Michael; url=https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID; _links=; id=4391b17e-8e06-45bf-b552-00117832fc
    19; uniqueName=smichael@microsoft.com; imageUrl=https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID; descriptor=aad.YjdjMTIwNGUtNzk2Zi03OTcyLThjYTEtODg1OT
    I4ZWUwNDk4}",
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_System.ExtensionMarker":  true,
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_Kanban.Column":  "Active",
                           "WEF_181E4A4E5273429291EAC4D88FDF44A3_Kanban.Column.Done":  false,
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_System.ExtensionMarker":  true,
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_Kanban.Column":  "Active",
                           "WEF_49E4DE99621F41948A90F1FC940D30DA_Kanban.Column.Done":  false,
                           "LK.Release":  "FY19-Q4",
                           "Custom.FeatureResolvedReasonPF":  "Unresolved",
                           "WEF_2904036E386A4928B52E5043CF160C8E_System.ExtensionMarker":  false,
                           "WEF_2904036E386A4928B52E5043CF160C8E_Kanban.Column":  "New",
                           "WEF_2904036E386A4928B52E5043CF160C8E_Kanban.Column.Done":  false,
                           "System.Tags":  "CS2AF; DevServices"
                       },
            "relations":  [
                              "@{rel=System.LinkTypes.Hierarchy-Reverse; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21959; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21966; attributes=}",
                              "@{rel=System.LinkTypes.Hierarchy-Forward; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21964; attributes=}"
                          ],
            "_links":  {
                           "self":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961}",
                           "workItemUpdates":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/updates}",
                           "workItemRevisions":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/revisions}",
                           "workItemComments":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961/comments}",
                           "html":  "@{href=https://dev.azure.com/LK/SOME_GUID/_workitems/edit/21961}",
                           "workItemType":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/Feature}",
                           "fields":  "@{href=https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields}"
                       },
            "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/21961"
        }
    ]
#>
function global:AzureDevOps-GetWorkItemsByQuery([string]$query)
{
    $header = AzureDevOps-AuthorizationHeader;
    $header['Content-Type'] = 'application/json';
    $body   = "{ ""query"":""$query"" }";
    $url    = "$global:AzureDevOpsUrlBasePF/_apis/wit/wiql?api-version=5.0";

    $wit    = Invoke-RestMethod -Method Post -Headers $header -Uri $url -Body $body;
    $urls   = ($wit.workItems).url;

    return ($urls | foreach { AzureDevOps-Get ($_ + '?$expand=All'); });
}

<#
.SYNOPSIS
  Updates the value of a field from a work item.
.DESCRIPTION
  Updates the value of a field from a work item.

.PARAMETER <id>
    Id of work item to be updated.
.PARAMETER <FieldName>
    Name of field to be updated.
.PARAMETER <FieldValue>
    New value for the field.


.OUTPUTS
  An object: the new work item, with the updated field.
  
.EXAMPLE
    AzureDevOps-UpdateWorkItemFieldValue 23916 'System.Title' 'CS2AF PRIV 0901 PlayStream API: Implement Action Processor.' | ConvertTo-Json
    {
        "id":  23916,
        "rev":  12,
        "fields":  {
                       "System.AreaPath":  "LK\\Developer Services",
                       "System.TeamProject":  "LK",
                       "System.IterationPath":  "LK\\2019\\1906\\Sprint 12 (Ends 6-14)",
                       "System.WorkItemType":  "User Story",
                       "System.State":  "Backlog",
                       "System.Reason":  "Moved to state Backlog",
                       "System.AssignedTo":  {
                                                 "displayName":  "Martin Gudgin",
                                                 "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                 "_links":  "@{avatar=}",
                                                 "id":  "SOME_GUID",
                                                 "uniqueName":  "mgudgin@microsoft.com",
                                                 "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                 "descriptor":  "aad.SOME_ID"
                                             },
                       "System.CreatedDate":  "2019-01-27T21:38:49.9Z",
                       "System.CreatedBy":  {
                                                "displayName":  "Martin Gudgin",
                                                "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                "_links":  "@{avatar=}",
                                                "id":  "SOME_GUID",
                                                "uniqueName":  "mgudgin@microsoft.com",
                                                "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                "descriptor":  "aad.SOME_ID"
                                            },
                       "System.ChangedDate":  "2019-05-24T16:04:54.19Z",
                       "System.ChangedBy":  {
                                                "displayName":  "Lucidio Kuhn",
                                                "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                                "_links":  "@{avatar=}",
                                                "id":  "SOME_GUID",
                                                "uniqueName":  "lumayerk@microsoft.com",
                                                "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                                "descriptor":  "aad.SOME_ID"
                                            },
                       "System.CommentCount":  0,
                       "System.Title":  "CS2AF PRIV 0901 PlayStream API: Implement Action Processor.",
                       "System.BoardColumn":  "Backlog",
                       "System.BoardColumnDone":  false,
                       "Microsoft.VSTS.Common.StateChangeDate":  "2019-01-27T21:38:49.9Z",
                       "Microsoft.VSTS.Common.Priority":  2,
                       "Microsoft.VSTS.Common.ValueArea":  "Business",
                       "LK.PMOwner":  {
                                               "displayName":  "Sarah Michael",
                                               "url":  "https://vssps.dev.azure.com/e/Microsoft/_apis/Identities/SOME_GUID",
                                               "_links":  "@{avatar=}",
                                               "id":  "SOME_GUID",
                                               "uniqueName":  "smichael@microsoft.com",
                                               "imageUrl":  "https://dev.azure.com/LK/_apis/GraphProfile/MemberAvatars/aad.SOME_ID",
                                               "descriptor":  "aad.SOME_ID"
                                           },
                       "WEF_B1279FEF64614C6BB43A9E85B0CD2834_Kanban.Column":  "Backlog",
                       "WEF_B1279FEF64614C6BB43A9E85B0CD2834_Kanban.Column.Done":  false,
                       "WEF_A720E604DE684AF99AD4A189041A0FFD_Kanban.Column":  "Backlog",
                       "WEF_A720E604DE684AF99AD4A189041A0FFD_Kanban.Column.Done":  false,
                       "Custom.TriagePF":  "Pending",
                       "Custom.TaskResolvedReasonPF":  "Backlog",
                       "System.Description":  "\u003cdiv\u003eImplement an Action processor for invoking Azure Function based CloudScript when a PlayStream event occurs.\u003c/div\u003e",
                       "System.Tags":  "CS2AF; DevServices; PrivatePreview"
                   },
        "relations":  [
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Reverse",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23915",
                              "attributes":  "@{isLocked=False; name=Parent}"
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23921",
                              "attributes":  "@{isLocked=False; name=Child}"
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/31199",
                              "attributes":  "@{isLocked=False; name=Child}"
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23923",
                              "attributes":  "@{isLocked=False; name=Child}"
                          },
                          {
                              "rel":  "System.LinkTypes.Hierarchy-Forward",
                              "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23922",
                              "attributes":  "@{isLocked=False; name=Child}"
                          }
                      ],
        "_links":  {
                       "self":  {
                                    "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916"
                                },
                       "workItemUpdates":  {
                                               "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/updates"
                                           },
                       "workItemRevisions":  {
                                                 "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/revisions"
                                             },
                       "workItemComments":  {
                                                "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916/comments"
                                            },
                       "html":  {
                                    "href":  "https://dev.azure.com/LK/SOME_GUID/_workitems/edit/23916"
                                },
                       "workItemType":  {
                                            "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItemTypes/User%20Story"
                                        },
                       "fields":  {
                                      "href":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/fields"
                                  }
                   },
        "url":  "https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/23916"
    }
#>
function global:AzureDevOps-UpdateWorkItemFieldValue([int]$id, [string]$FieldName, [string]$FieldValue)
{
    return AzureDevOps-UpdateWorkItemFieldValues $id @{ "$FieldName" = $FieldValue };
}

<#
.SYNOPSIS
  Updates values of fields from a work item.
.DESCRIPTION
  Updates values of fields from a work item.

.PARAMETER <id>
    Id of work item to be updated.
.PARAMETER <newValues>
    A dictionary (Hashtable) with the new values, where the key is the field name.

.OUTPUTS
  An object: the new work item, with the updated fields.
  
.EXAMPLE
    # IMPORTANT: Notice the double backslashes on AreaPath, in order to un-escape.
    AzureDevOps-UpdateWorkItemFieldValues 23916 @{ 'System.Title'='CS2AF PRIV 0901 PlayStream API: Implement Action Processor.'; 'System.AreaPath'='LK\\Developer Services' }
#>
function global:AzureDevOps-UpdateWorkItemFieldValues([int]$id, [Hashtable]$newValues)
{
    $header = AzureDevOps-AuthorizationHeader;
    $header['Content-Type'] = 'application/json-patch+json';
    $replaces = [string]::Join(',', ( $newValues.Keys | select | foreach { "{""op"":""replace"", ""path"":""/fields/$_"", ""value"":""$($newValues[$_])""}" }));
    $body   = "[$replaces]";
    $wi     = Invoke-RestMethod -Method Patch -Headers $header -Uri "$global:AzureDevOpsUrlBasePF/_apis/wit/workitems/$($id)?api-version=5.0" -Body $body;
    return $wi;
}

<#
.SYNOPSIS
  Creates a new work item with the given values.
.DESCRIPTION
  Creates a new work item with the given values.

.PARAMETER <WorkItemType>
    The work item type. Must be either Task, User Story, Feature, Bug or Epic.
.PARAMETER <values>
    A dictionary (Hashtable) with the new values, where the key is the field name.

.OUTPUTS
  An object: the new work item.
  
.EXAMPLE
    # IMPORTANT: Notice the double backslashes on AreaPath, in order to un-escape.
    $workItem = AzureDevOps-CreateWorkItem 'Task' @{ 'System.Title'='CS2AF 1010 Delete me later.'; 'System.AreaPath'='LK\\Developer Services' }
    $workItem
    id     : 31746
    rev    : 1
    fields : @{System.AreaPath=LK\Developer Services; System.TeamProject=LK; System.IterationPath=LK; System.WorkItemType=Task; System.State=Backlog; System.Reason=Moved to state Backlog; 
             System.CreatedDate=2019-05-24T17:38:06.963Z; System.CreatedBy=; System.ChangedDate=2019-05-24T17:38:06.963Z; System.ChangedBy=; System.CommentCount=0; System.Title=CS2AF 1010 Delete me later.; 
             Microsoft.VSTS.Common.StateChangeDate=2019-05-24T17:38:06.963Z; Microsoft.VSTS.Common.Priority=2; Custom.TriagePF=Pending; Custom.TaskResolvedReasonPF=Backlog}
    _links : @{self=; workItemUpdates=; workItemRevisions=; workItemComments=; html=; workItemType=; fields=}
    url    : https://dev.azure.com/LK/SOME_GUID/_apis/wit/workItems/31746
#>
function global:AzureDevOps-CreateWorkItem([string]$WorkItemType,[Hashtable]$values)
{
    $header                 = AzureDevOps-AuthorizationHeader;
    $header['Content-Type'] = 'application/json-patch+json';
    $replaces               = [string]::Join(',', ( $values.Keys | select | foreach { "{""op"":""add"", ""path"":""/fields/$_"", ""from"":null, ""value"":""$($values[$_])""}" }));
    $body                   = "[$replaces]";
    $url                    = "$global:AzureDevOpsUrlBasePFPF/_apis/wit/workitems/`$$($WorkItemType)?api-version=5.0";
    $wi                     = Invoke-RestMethod -Method POST -Headers $header -Uri $url -Body $body;
    return $wi;
}


<#
.SYNOPSIS
  Deletes a work item, by item ID.
.DESCRIPTION
  Deletes a work item, by item ID.

.PARAMETER <id>
    ID of item to be deleted.

.OUTPUTS
  An object with fields related to the deleted work item, including a url to the recycle bin.
  
.EXAMPLE
    # Notice that the work item will be temporarily available through the returned url.
    AzureDevOps-GetWorkItem 23916
    id          : 31746
    type        : Task
    name        : CS2AF 1010 Delete me later.
    project     : LK
    deletedDate : 5/24/2019 5:43:28 PM
    deletedBy   : Lucidio Kuhn <lumayerk@microsoft.com>
    code        : 200
    url         : https://dev.azure.com/LK/SOME_GUID/_apis/wit/recyclebin/31746
    resource    : @{id=31746; rev=2; fields=; _links=; url=https://dev.azure.com/LK/SOME_GUID/_apis/wit/recyclebin/31746}
#>
function global:AzureDevOps-DeleteWorkItem([int]$id)
{
    $header                 = AzureDevOps-AuthorizationHeader;
    $url                    = "$global:AzureDevOpsUrlBasePF/_apis/wit/workitems/$($id)?api-version=5.0";
    $wi                     = Invoke-RestMethod -Method DELETE -Headers $header -Uri $url -Body $body;
    return $wi;
}


<#
.SYNOPSIS
  For all work items that have a given tag:
    If the work item has children:
        Update the iteration path (which indicates which sprint the item will be delivered) with the maximum iteration path from its children.
.DESCRIPTION
  For all work items that have a given tag:
    If the work item has children:
        Update the iteration path (which indicates which sprint the item will be delivered) with the maximum iteration path from its children.

.PARAMETER <tag>
    Tag that identifies which set of work items we want to update iteration paths.

.OUTPUTS
  Nothing usable, except the iteration paths being updated at Azure DevOps.
  
.EXAMPLE
    AzureDevOps-UpdateWorkItemFieldValues 23916 @{ 'System.Title'='CS2AF PRIV 0901 PlayStream API: Implement Action Processor.'; 'System.AreaPath'='LK\Developer Services' }
#>
function global:AzureDevOps-PropagateIterationPathUp([string]$tag)
{
    foreach ($workItemType in @('Task', 'User Story', 'Feature'))
    {
        $workItems = AzureDevOps-GetWorkItemsByQuery "select * From WorkItems Where [Tags] Contains '$tag' and [Work Item Type] = '$workItemType'";
        foreach ($workItem in $workItems)
        {
            $workItemChildren     = $workItem.relations | where { $_.attributes.name -eq 'Child' };
            if ($workItemChildren -ne $null -and $workItemChildren.Count -gt 0)
            {
                $urls = ($workItemChildren).url;
                $IterationIds = $urls | foreach { (AzureDevOps-Get ($_ + '?$expand=All')).fields.'System.IterationId' };
                $maximumIterationId = ($IterationIds | measure -Maximum).Maximum;
                if (!([string]::IsNullOrEmpty($maximumIterationId)) -and $maximumIterationId -ne $workItem.fields.'System.IterationId')
                {
                    Write-Host "Updating Iteration Path for $($workItem.Id) [$(($workItem.fields.'System.WorkItemType').PadRight(9))] [$(($workItem.fields.'System.Title').PadRight(48).Substring(0, 48))] to [$maximumIterationId]" -ForegroundColor Green;
                    [void](AzureDevOps-UpdateWorkItemFieldValue $workItem.Id 'System.IterationId' $maximumIterationId);
                }
            }
        }
    }
}

<#
.SYNOPSIS
  Retrieves all tasks from a given MS Project file.
  Microsoft Project must be installed on this computer in order to use this.

  This script requires that no instances of Microsoft Project be running before it starts.
  Therefore there is the Confirm parameter, which, if true, will ask the user whether they want to stop all instances of Microsoft Project.
  This is because this script uses the MSProject.Application COM object, which is finicky with regards of multiple instances, just like all Office apps.
  So, if you want to use this without user intervention, use Confirm $false, but make sure Microsofr Project is not running before you call AzureDevOps-GetTasksFromMSProject.

.DESCRIPTION
  Retrieves all tasks from a given MS Project file.

.PARAMETER <msProjectFilePath>
    Path to the .mpp file from which we want to retrieve its tasks.

.PARAMETER <Confirm>
    If true, this script will stop and ask whether you want to stop all instances of Microsoft Project. If you accept, the script will stop all instances of Microsoft Project.
    If false, this script will not ask neither try to stop Microsoft Project.

    Default is true.

.PARAMETER <ExpandAllFields>
    If true, it will bring all fields from all tasks.
    If false, it will bring only ID, Name, Start, Finish and Duration in days.

    Bringing all fields is significantly slower.
    Defaults is false.
.OUTPUTS
  A list with data extracted from the project's tasks.
  
.EXAMPLE
    AzureDevOps-GetTasksFromMSProject 'C:\Users\lumayerk.REDMOND\OneDrive - Microsoft\CS2AF.mpp' | select -First 2 | ConvertTo-Json
    [
        {
            "_WorkItemStart":  "\/Date(1558537200000)\/",
            "_WorkName":  "CS2AF 020101 Sample Code: Server-side sample code (AF examples)",
            "_WorkItemFinish":  "\/Date(1559001600000)\/",
            "_WorkDurationInDays":  4,
            "_WorkItemId":  "21987"
        },
        {
            "_WorkItemStart":  "\/Date(1559055600000)\/",
            "_WorkName":  "CS2AF 020102 Sample Code: Client-side sample code (Games, etc.)",
            "_WorkItemFinish":  "\/Date(1559174400000)\/",
            "_WorkDurationInDays":  2,
            "_WorkItemId":  "21988"
        }
    ]
#>
function global:AzureDevOps-GetTasksFromMSProject([string]$msProjectFilePath, [bool]$Confirm = $true, [bool]$ExpandAllFields = $false)
{
    function jj($o) { return (ConvertTo-Json -InputObject $o -Depth 32 -Compress | ConvertFrom-Json) }

    function StopMSProjectIfNeeded([bool]$Confirm)
    {
        if ($Confirm)
        {
            $dialog   = new-object -comobject wscript.shell;
            $yes      = 6;
            $title    = "Attention!";
            $message  = "About to close all MS Project instances (if there is any).`nDo you want to proceed?";
            $response = $dialog.popup($message, 0, $title, 4);
            if ($response -eq $yes)
            {
                get-process -Name winproj -ErrorAction Ignore | foreach { Stop-Process $_ }          
            }
        }
    }

    StopMSProjectIfNeeded $Confirm;
    Invoke-Item -Path $msProjectFilePath;
    try
    {
        $project = new-object -ComObject MSProject.Application;
    }
    catch
    {
        throw "Microsoft Project is not installed on this computer. Please install Microsoft Project, then try again.";
    }

    # Wait until we can get the project tasks.
    for ($i = 0; $i -lt 16; $i++)
    {
        if ($project.ActiveProject.Tasks.Count -gt 0)
        {
            break;
        }
        else
        {
            Start-Sleep -Seconds 2;
        }
    }

    $tasks   = @();
    $project.ActiveProject.Tasks | foreach { 
        $task          = @{ };
        $task['_WorkItemId']         = $_.text10;
        $task['_WorkName']           = $_.Name;
        $task['_WorkDurationInDays'] = $_.Duration1/480;
        $task['_WorkItemStart']      = $_.Start;
        $task['_WorkItemFinish']     = $_.Finish;

        if ($ExpandAllFields)
        {
            $propertyNames = $null;
            for ($i = 0; $i -lt 16 -and $propertyNames -eq $null; $i++)
            {
                try { $propertyNames = (get-member -InputObject $_ -MemberType Property).Name; } catch{}
                if ($propertyNames -eq $null) 
                { 
                    Start-Sleep -Milliseconds 100; 
                };
            }
        
            foreach ($propertyName in $propertyNames)
            {
                $task[$propertyName] = $_."$propertyName";
            }
        }

        $tasks += $task;
    };

    return $tasks;
}

<#
.SYNOPSIS
  Updates Azure DevOps work items with data from a Microsoft Project project file.
  Microsoft Project must be installed on this computer in order to use this.

  This script requires that no instances of Microsoft Project be running before it starts.
  Therefore there is the Confirm parameter, which, if true, will ask the user whether they want to stop all instances of Microsoft Project.
  This is because this script uses the MSProject.Application COM object, which is finicky with regards of multiple instances, just like all Office apps.
  So, if you want to use this without user intervention, use Confirm $false, but make sure Microsofr Project is not running before you call AzureDevOps-GetTasksFromMSProject.

  Currently, the data items that are being updated are:
    Microsoft.VSTS.Scheduling.StartDate
    Microsoft.VSTS.Scheduling.FinishDate
.DESCRIPTION
  Retrieves all tasks from a given MS Project file.

.PARAMETER <msProjectFilePath>
    Path to the .mpp file from which we want to retrieve its tasks.

.PARAMETER <Confirm>
    If true, this script will stop and ask whether you want to stop all instances of Microsoft Project. If you accept, the script will stop all instances of Microsoft Project.
    If false, this script will not ask neither try to stop Microsoft Project.

    Default is true.

.OUTPUTS
  Nothing useful.
  
.EXAMPLE
    AzureDevOps-UpdateWorkItemsWithDataFromMSProject 'C:\Users\lumayerk.REDMOND\OneDrive - Microsoft\CS2AF.mpp'

#>
function global:AzureDevOps-UpdateWorkItemsWithDataFromMSProject([string]$msProjectFilePath, [bool]$Confirm = $true)
{
    function UDT([DateTime]$d)
    {
        return ($d.ToUniversalTime().ToString('s') + 'Z')
    }
    $tasks = AzureDevOps-GetTasksFromMSProject $msProjectFilePath $Confirm;
    foreach ($task in $tasks)
    {
        [void](AzureDevOps-UpdateWorkItemFieldValues $task._WorkItemId @{ 'Microsoft.VSTS.Scheduling.StartDate' = (UDT $task._WorkItemStart); 'Microsoft.VSTS.Scheduling.FinishDate' = (UDT $task._WorkItemFinish) });
    }
}
