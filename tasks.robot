*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Excel.Files
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv file
    Close the annoying modal
    Guardar datos en variable desde csv
    Create ZIP package from PDF files
    [Teardown]    Cerrar Todos los Navegadores


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Guardar datos en variable desde csv
    ${orders}=    Get Order
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Ingresar datos al formulario    ${order}    ${order}[Order number]
    END

Get Order
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Ingresar datos al formulario
    [Arguments]    ${fila}    ${pdf}
    Select From List By Value    //select[@name="head"]    ${fila}[Head]
    Click Element    //label[@for="id-body-${fila}[Body]"]
    Input Text    (//input[@class='form-control'])[1]    ${fila}[Legs]
    Input Text    (//input[@class='form-control'])[2]    ${fila}[Address]
    Execute Javascript    window.scrollTo(0,1000)
    Sleep    2s
    Click Button    (//button[@type='submit'])[1]
    Sleep    3s
    Click Button    (//button[@type='submit'])[2]
    Sleep    3s
    ${boton}=    Get Element Status    (//button[@type='submit'])[2]
    WHILE    ${boton}[visible]
        Click Button    (//button[@type='submit'])[2]
        ${boton}=    Get Element Status    (//button[@type='submit'])[2]
    END
    Wait Until Element Is Visible    //h3[contains(.,'Receipt')]
    Export the table as a PDF    ${pdf}
    Click Button    //button[@id='order-another']
    Sleep    3s
    Close the annoying modal

Export the table as a PDF
    [Arguments]    ${nombrePdf}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${screenshot}=    Screenshot    //div[contains(@id,'robot-preview')]    ${OUTPUT_DIR}${/}${nombrePdf}.png
    ${elemetospdf}=    Create List    ${sales_results_html}
    Html To Pdf    ${elemetospdf}    ${OUTPUT_DIR}${/}${nombrePdf}.pdf
    Sleep    2s
    Open Pdf    ${OUTPUT_DIR}${/}${nombrePdf}.pdf
    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}${nombrePdf}.png    ${OUTPUT_DIR}${/}${nombrePdf}.pdf
    Close Pdf    ${OUTPUT_DIR}${/}${nombrePdf}.pdf
    Remove File    ${OUTPUT_DIR}${/}${nombrePdf}.png

Close the annoying modal
    Wait Until Element Is Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}
    ...    ${zip_file_name}
    ...    include=*.pdf
    Remove File    ${OUTPUT_DIR}${/}*.pdf

Cerrar Todos los Navegadores
    Close All Browsers
