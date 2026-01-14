import re
import spacy
from typing import Dict, Any, List
import logging

logger = logging.getLogger(__name__)

class ResumeExtractor:
    def __init__(self):
        logger.info("Initializing NLP engine (spaCy)...")
        try:
            # Using a blank model for local-only, fast extraction
            self.nlp = spacy.blank("en")
        except:
            logger.warning("spaCy initialization failed. Text extraction will rely on Regex only.")
            self.nlp = None

    def extract_from_text(self, text: str) -> Dict[str, Any]:
        """
        Extracts structured data from raw resume text using Regex and NLP.
        """
        data = {
            "name": self._extract_name(text),
            "email": self._extract_email(text),
            "phone": self._extract_phone(text),
            "skills": self._extract_skills(text),
            "workExperience": self._extract_experience(text),
            "education": self._extract_education(text),
            "bio": self._extract_bio(text),
            "location": self._extract_location(text)
        }
        return data

    def _extract_name(self, text: str) -> str:
        # Simple heuristic: first non-empty line after cleaning
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        if lines:
            # Usually name is at the top
            return lines[0]
        return ""

    def _extract_email(self, text: str) -> str:
        pattern = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'
        match = re.search(pattern, text)
        return match.group(0) if match else ""

    def _extract_phone(self, text: str) -> str:
        # Support various formats like +91, (012), 123-456, etc.
        pattern = r'(\+?\d{1,3}[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}'
        match = re.search(pattern, text)
        return match.group(0) if match else ""

    def _extract_skills(self, text: str) -> List[str]:
        # Common skills list (expandable)
        common_skills = [
            'flutter', 'dart', 'firebase', 'python', 'javascript', 'react', 'node', 
            'java', 'c++', 'sql', 'nosql', 'git', 'docker', 'aws', 'ui', 'ux', 
            'android', 'ios', 'html', 'css', 'fastapi', 'spacy', 'tensorflow'
        ]
        text_lower = text.lower()
        found_skills = []
        for skill in common_skills:
            if re.search(rf'\b{skill}\b', text_lower):
                # Format to capitalized or proper case
                found_skills.append(skill.upper() if len(skill) <= 3 else skill.capitalize())
        return found_skills

    def _extract_experience(self, text: str) -> List[Dict[str, str]]:
        # This is a complex part. For now, we'll look for sections
        exp_list = []
        # Look for "Experience" or "Work History" sections
        exp_header = re.search(r'(EXPERIENCE|WORK HISTORY|PROFESSIONAL EXPERIENCE)', text, re.IGNORECASE)
        if exp_header:
            section_text = text[exp_header.end():].split('EDUCATION')[0].split('SKILLS')[0]
            # Heuristic: split by double newline or date patterns
            # This is a placeholder for more advanced parsing
            lines = [l.strip() for l in section_text.split('\n') if l.strip()]
            if lines:
                exp_list.append({
                    "title": lines[0],
                    "company": lines[1] if len(lines) > 1 else "",
                    "duration": "Duration detected",
                    "description": "\n".join(lines[2:5]) if len(lines) > 2 else ""
                })
        return exp_list

    def _extract_education(self, text: str) -> List[Dict[str, str]]:
        edu_list = []
        edu_header = re.search(r'(EDUCATION|ACADEMIC BACKGROUND)', text, re.IGNORECASE)
        if edu_header:
            section_text = text[edu_header.end():].split('EXPERIENCE')[0].split('SKILLS')[0]
            lines = [l.strip() for l in section_text.split('\n') if l.strip()]
            if lines:
                edu_list.append({
                    "degree": lines[0],
                    "institution": lines[1] if len(lines) > 1 else "",
                    "year": "Year detected"
                })
        return edu_list

    def _extract_bio(self, text: str) -> str:
        # Summary or Objective section
        bio_header = re.search(r'(SUMMARY|OBJECTIVE|BIO|ABOUT ME)', text, re.IGNORECASE)
        if bio_header:
            section_text = text[bio_header.end():].split('\n\n')[0]
            return section_text.strip()
        return ""

    def _extract_location(self, text: str) -> str:
        # Look for City, State/Country patterns
        # Simple placeholder
        pattern = r'[A-Z][a-z]+,\s[A-Z][a-z]+'
        match = re.search(pattern, text)
        return match.group(0) if match else "Location not detected"
