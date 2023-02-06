*** Settings ***
Library     RequestsLibrary


*** Test Cases ***
TC-001 Verify when input wrong username or password, API should return error
    #call API with wrong username / password
    Create Session      loginSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio123  password=12345
    ${resp}=    POST On Session     loginSession    /login      json=${request_body}    expected_status=401
    Should Be Equal     ${resp.json()['status']}    error
    Should Be Equal     ${resp.json()['message']}    invalid username or password

TC-002 Verify That Can Get Asset List From Get API correctly
    #call API to login and get token 
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=    POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=   Set Variable    ${resp.json()['message']}
    ${headers}=     Create Dictionary       token=${token}
    #call Get API to get asset (with token) and verify status code is 200
    ${get_resp}=    GET On Session      assetSession    /assets         headers=${headers}
    #check response contains at least 1 assets
    ${count}=       Get Length  ${get_resp.json()}
    ${morethanone}=     Evaluate    ${count}>0
    Should Be True      ${morethanone}

TC-003 Verify that get asset API always require valid token
    #call asset API with invalid token or with no token 
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=    POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${falseToken}=   Create Dictionary       message=falseToken
    #check response code = 401 
    ${get_resp}=    GET On Session      assetSession    /assets     headers=${falseToken}        expected_status=401 
    ${get_resp}=    GET On Session      assetSession    /assets     expected_status=401 
    #check error message 
    Should Be Equal     ${get_resp.json()['message']}      you do not have access to this resource

TC-004 Verify that create asset API can work correctly 
    #call create asset API (POST /assets) with valid token
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=    POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=   Set Variable    ${resp.json()['message']}
    ${headers}=     Create Dictionary       token=${token}
    ${new_asset}=       Create Dictionary   assetId=a156c     assetName=Macpro m1   assetType=1      inUse=true
    #check response code = 200 
    ${post_resp}=       POST On Session     assetSession    /assets      json=${new_asset}    headers=${headers}    expected_status=200    
    #check status message = success
    ${check_asset}=       Should Be Equal     ${post_resp.json()['status']}      success        
    #check that created asset can be returned from GET /assets
    ${get_resp}=    GET On Session      assetSession    /assets     headers=${headers}

                 
TC-005 Verify that cannot create asset with duplicated ID 
    #call create asset with valid token but use duplicate asset ID 
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=            POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=           Set Variable    ${resp.json()['message']}
    ${headers}=         Create Dictionary       token=${token}
    ${new_asset}=       Create Dictionary   assetId=a004     assetName=Macpro m1   assetType=1      inUse=true
    ${post_resp}=       POST On Session     assetSession    /assets      json=${new_asset}    headers=${headers}    
    # check status message
    ${check_msg}=       Set Variable     ${post_resp.json()['message']}     
    ${check_sts}=       Set Variable     ${post_resp.json()['status']}
    ${sts_msg}=         Create Dictionary      status=${check_sts}    message=${check_msg}
    Should be Equal     ${sts_msg['status']}    failed
    Should be Equal     ${sts_msg['message']}   id : ${new_asset['assetId']} is already exists , please try with another id    
    # check that no duplicated asset returned from GET /assets
    Get On Session      assetSession    /assets    headers=${headers} 

TC-006 Verify that modify asset API can work correctly 
    #call modify asset with valid token and try to change name of some asset
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=    POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=   Set Variable    ${resp.json()['message']}
    ${headers}=     Create Dictionary       token=${token}
    ${updated_asset}=    Create Dictionary      assetId=a004     assetName=Macpro m2    assetType=1      inUse=true
    ${modify_asset}=     PUT On Session     assetSession    /assets      json=${updated_asset}    headers=${headers}    expected_status=200  
    #check status message = success
    ${check_sts}=       Set Variable     ${modify_asset.json()['status']} 
    ${sts_msg}=         Create Dictionary      status=${check_sts}    
    Should be Equal     ${sts_msg['status']}    success
    #call get api to check that asset Name has been changed 
    Get On Session      assetSession    /assets    headers=${headers}

TC-007 Verify that delete asset API can work correctly
    #call delete asset 
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=            POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=           Set Variable    ${resp.json()['message']}
    ${headers}=         Create Dictionary       token=${token}
    ${new_asset}=       Create Dictionary   assetId=a156c     assetName=Macpro m1   assetType=1      inUse=true        
    ${del}=             DELETE On Session   assetSession    /assets/${new_asset['assetId']}      json=${new_asset}    headers=${headers}    expected_status=200   
    #call GET to check that asset has been deleted 
    Get On Session      assetSession    /assets    headers=${headers}


TC-008 Verify that cannot delete asset which ID does not exists 
    #call delete asset with non-existing id
    #call delete asset 
    Create Session      assetSession             http://localhost:8082
    ${request_body}=    Create Dictionary   username=doppio  password=weBuildBestQa
    ${resp}=            POST On Session     assetSession    /login      json=${request_body}    expected_status=200
    ${token}=           Set Variable    ${resp.json()['message']}
    ${headers}=         Create Dictionary       token=${token}
    ${new_asset}=       Create Dictionary   assetId=0000     assetName=Macpro m1   assetType=1      inUse=true        
    ${del}=             DELETE On Session   assetSession    /assets/${new_asset['assetId']}      json=${new_asset}    headers=${headers}    expected_status=200  
    #check error message
    ${check_msg}=       Set Variable     ${del.json()['message']}     
    ${check_sts}=       Set Variable     ${del.json()['status']}
    ${sts_msg}=         Create Dictionary      status=${check_sts}    message=${check_msg} 
    Should Be Equal     ${sts_msg['message']}     cannot find this id in database





