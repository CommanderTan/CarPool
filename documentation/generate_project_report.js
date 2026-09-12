const fs = require('fs');
const { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, WidthType } = require('docx');

const doc = new Document({
  sections: [{
    properties: {},
    children: [
      new Paragraph({ text: "Car Pool Application Project Report", heading: HeadingLevel.TITLE }),

      new Paragraph({ text: "Introduction", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "This project aims to develop a mobile application for car pooling, allowing users to share rides, reduce commuting costs, and contribute to environmental sustainability." }),

      new Paragraph({ text: "Technologies Used", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "The application is built using the Flutter framework, utilizing Firestore as the backend database. Other key technologies include Provider for state management, Firebase Authentication for user security, and Google Maps API for geolocation." }),

      new Paragraph({ text: "System Architecture", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "The system follows a modular architecture, separating the UI layer (Screens), state management layer (Providers), and data layer (Models/Services)." }),

      new Paragraph({ text: "Project Features", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "1. User Authentication (Login/Signup)" }),
      new Paragraph({ text: "2. Ride Creation and Search" }),
      new Paragraph({ text: "3. Cab Sharing capabilities" }),
      new Paragraph({ text: "4. Real-time Ride Status Updates" }),

      new Paragraph({ text: "Future Enhancements", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "Future versions will implement more advanced route optimization algorithms and enhanced payment integration, alongside social features." }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("D:/car_pool/documentation/Car_Pool_Project_Report.docx", buffer);
  console.log("Document created successfully.");
});
