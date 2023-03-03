*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open Robot Spare Inc Website
    Click on the popup ok button
    Download the csv file
    Get Orders
    [Teardown]    Close the browser


*** Keywords ***
Open Robot Spare Inc Website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Click on the popup ok button
    Click Button    xpath://*[text()="OK"]

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill and submit the form for one order
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:(//input)[7]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Collect the robot image    ${order}
    Click Button    id:order
    ${isErrorDisplayed}=    Run Keyword And Return Status
    ...    Element Should Be Visible
    ...    //*[@class="alert alert-danger"]
    Log To Console    ${isErrorDisplayed}
    WHILE    ${isErrorDisplayed}    limit=10
        Click Button    id:order
        ${isRecieptDisplayed}=    Run Keyword And Return Status
        ...    Element Should Be Visible
        ...    id:receipt

        IF    ${isRecieptDisplayed}            BREAK
    END
    Export the table as a PDF    ${order}
    Click Button    id:order-another
    Click on the popup ok button

Handle error and proceed

Get Orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Fill and submit the form for one order    ${order}
    END

Collect the robot image
    [Arguments]    ${order}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}images${/}${order}[Order number].png

Export the table as a PDF
    [Arguments]    ${order}
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}pdfs${/}${order}[Order number].pdf
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}pdfs${/}${order}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}images${/}${order}[Order number].png
    Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}final${/}${order}[Order number].pdf

Close the browser
    Close Browser
