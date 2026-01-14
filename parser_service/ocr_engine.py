import logging
from doctr.io import DocumentFile
from doctr.models import ocr_predictor
import os

logger = logging.getLogger(__name__)

class OCREngine:
    def __init__(self):
        logger.info("Initializing Fast DocTR OCR predictor...")
        # Use fast MobileNetV3 architectures and lower resolution for speed
        self.model = ocr_predictor(
            det_arch='db_mobilenet_v3_large',
            reco_arch='crnn_mobilenet_v3_small',
            pretrained=True,
            assume_straight_pages=True,
            preserve_aspect_ratio=True,
            symmetric_pad=False
        )
        logger.info("Fast DocTR OCR predictor initialized.")

    def extract_text(self, file_path: str) -> str:
        """
        Extracts raw text from a PDF or image file using DocTR.
        """
        try:
            extension = os.path.splitext(file_path)[1].lower()
            
            if extension == '.pdf':
                doc = DocumentFile.from_pdf(file_path)
            elif extension in ['.jpg', '.jpeg', '.png']:
                doc = DocumentFile.from_images(file_path)
            else:
                raise ValueError(f"Unsupported file format: {extension}")

            # Run OCR
            result = self.model(doc)
            
            # Export result to text
            # DocTR result.render() provides structured text
            full_text = ""
            for page in result.pages:
                for block in page.blocks:
                    for line in block.lines:
                        line_text = " ".join([word.value for word in line.words])
                        full_text += line_text + "\n"
                    full_text += "\n"
            
            return full_text.strip()
            
        except Exception as e:
            logger.error(f"OCR Error: {str(e)}")
            raise e
