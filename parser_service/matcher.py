import logging
import numpy as np
from typing import List, Dict, Any
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

class MatcherEngine:
    def __init__(self, model_name: str = 'all-MiniLM-L6-v2'):
        """
        Initializes the Matcher Engine with a specific Sentence Transformer model.
        """
        logger.info(f"Loading Matcher Model: {model_name}...")
        try:
            self.model = SentenceTransformer(model_name)
            logger.info("Matcher Model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load model {model_name}: {e}")
            self.model = None

    def encode_text(self, text: str) -> np.ndarray:
        """
        Encodes a single string into a vector.
        """
        if self.model is None:
            return np.zeros(384) # Default size for MiniLM
        return self.model.encode(text)

    def calculate_similarity(self, vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Calculates cosine similarity between two vectors.
        """
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
            
        return np.dot(vec1, vec2) / (norm1 * norm2)

    def match_worker_to_jobs(self, worker_profile: Dict[str, Any], jobs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Matches a worker profile against a list of jobs.
        Returns the jobs with a match_score added, sorted by score.
        """
        # Construct worker text representation
        worker_skills = " ".join(worker_profile.get("skills", []))
        worker_text = f"{worker_profile.get('profile_title', '')} {worker_profile.get('bio', '')} {worker_skills}"
        worker_vec = self.encode_text(worker_text)

        matches = []
        for job in jobs:
            # Construct job text representation
            job_skills = " ".join(job.get("required_skills", []))
            job_text = f"{job.get('title', '')} {job.get('description', '')} {job_skills}"
            job_vec = self.encode_text(job_text)

            similarity = self.calculate_similarity(worker_vec, job_vec)
            
            # Simple weighted score (can be expanded)
            score = float(similarity * 100)
            
            # Add reasoning (simplified)
            reasons = []
            if score > 80:
                reasons.append("Strong Skill Match")
            elif score > 60:
                reasons.append("Good Potential")
                
            job_with_score = job.copy()
            job_with_score['match_score'] = round(score, 1)
            job_with_score['match_reasons'] = reasons
            matches.append(job_with_score)

        # Sort by score descending
        matches.sort(key=lambda x: x['match_score'], reverse=True)
        return matches
