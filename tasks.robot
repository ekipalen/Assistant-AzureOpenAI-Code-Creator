*** Settings ***
Documentation       ChatGPT Robot Helper
Library    RPA.Browser.Playwright
Library    RPA.FileSystem
Library    RPA.OpenAI
Library    RPA.Robocorp.Vault
Library    RPA.Assistant
Library    RPA.Desktop
#Suite Setup   Auth to OpenAI
Suite Setup    Auth to Azure OpenAI

*** Variables ***
${LOCATORS}    //input | //button | //select
${URL}   https://www.rpa-unlimited.com/youtube/robocorp-tutorial/
${HTML_ELEMENTS}
${CREATE_SELECTORS}

*** Tasks ***
Minimal task
    Display Main Menu
    ${result}=    RPA.Assistant.Run Dialog
    ...    title=Azure OpenAI Code Helper
    ...    on_top=False
    ...    height=850
    ...    width=850
    ...    timeout=10720
    ...    location=Center

*** Keywords ***
Auth to OpenAI 
    ${secrets}    Get Secret   OpenAI
    Authorize To Openai    api_key=${secrets}[key]

Auth to Azure OpenAI
    ${secrets}    Get Secret   AzureOpenAI
    Authorize To Azure Openai     
    ...    api_key=${secrets}[api_key]    
    ...    api_base=${secrets}[api_base]   #https://openairobocorptest.openai.azure.com/
    ...    api_type=azure  #optional
    ...    api_version=2023-05-15  #optional

Display Main Menu
    Clear Dialog
    Add Image    resources/logo.png   width=40   height=40
    Add Heading    ChatGPT Code Helper
    Open Row
    Add Drop-Down
    ...    name=syntax
    ...    options=Python,Robot Framework
    ...    default=Python
    ...    label=Syntax
    Add Drop-Down    browser_library    None,RPA.Browser.Playwright,RPA.Browser.Selenium   label=Browser Library   
    Close Row
    Add Text Input    user_prompt   Write a description for the robot    minimum_rows=8  maximum_rows=8
    Open Row
    Add Button    Open Browser to get html elements    Open browser to find the elements
    Close Row
    Add Next Ui Button    Create Code    Create Code
    Add Submit Buttons    buttons=Close    default=Close

Create Code
    [Arguments]    ${form}
    IF    '${CREATE_SELECTORS}' == 'True'
        Find the Elements    
        ${HTML_ELEMENTS}    Read File    output/element_htmls.txt
    END
    
    IF    '${form}[syntax]' == 'Python'
        ${base_prompt}   Read File    resources/prompt_python.txt
    ELSE
        ${base_prompt}   Read File    resources/prompt_rf.txt
    END

    ${user_prompt}   Set Variable   ${form}[user_prompt]

    #${response}    @{conversation}    Chat Completion Create
    #...    user_content=${base_prompt} Instruction: ${user_prompt} Html data if needed: \n${HTML_ELEMENTS}.
    #...    model=gpt-3.5-turbo    

    ${response}   @{conversation}=     Chat Completion Create
    ...    user_content=${base_prompt} Instruction: ${user_prompt} Html data if needed: \n${HTML_ELEMENTS}.
    ...    model=gpt35turbo_test
    
    Clear Dialog 
    Add Heading    Robot Code
    Add Text    ${response}
    Create File    output/robotfile.txt   ${response}   overwrite=True
    Add Button    Open the result file    Open application    notepad.exe   output/robotfile.txt
    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Find the Elements
    ${URL}   Get Url
    ${elements}   Get Elements    ${LOCATORS}
    ${element_count}    Get Element Count    ${LOCATORS}
    IF    ${element_count} > ${0}
        Create File    output/element_htmls.txt   overwrite=True
        Append To File    output/element_htmls.txt    Url: ${URL}\n
        FOR    ${element}    IN    @{elements}
            ${entities}    Get Elements    ${element}
            FOR    ${entity}    IN    @{entities}
                ${html}   Get Property   ${entity}    outerHTML
                RPA.Browser.Playwright.Highlight Elements    ${entity}    width=5px   style=solid   color=red   duration=3
                Append To File    output/element_htmls.txt    ${html}
            END
            Append To File    output/element_htmls.txt    \n
        END
    END

Open browser to find the elements
    Open Browser   ${URL}
    ${CREATE_SELECTORS}   Set Variable   True
    Set Suite Variable    ${CREATE_SELECTORS}

Back To Main Menu
    [Arguments]   ${form}
    Display Main Menu
    Refresh Dialog