import React, { useState, useMemo } from 'react';
import DOMPurify from 'dompurify';
import type { NewsArticle } from '../../types/news';

interface ArticleBodyProps {
  article: NewsArticle;
}

interface DisplayImage {
  url: string;
  caption?: string;
  alt?: string;
}

export default function ArticleBody({ article }: ArticleBodyProps) {
  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const [imgError, setImgError] = useState(false);
  const [imgLoaded, setImgLoaded] = useState(false);

  // Collect all unique images: coverImage + all galleryImages
  const allImages = useMemo<DisplayImage[]>(() => {
    const list: DisplayImage[] = [];
    const seen = new Set<string>();

    if (article.coverImage && article.coverImage.trim()) {
      const trimmed = article.coverImage.trim();
      list.push({ url: trimmed, caption: '', alt: article.title });
      seen.add(trimmed);
    }

    if (article.galleryImages && Array.isArray(article.galleryImages)) {
      article.galleryImages.forEach((g) => {
        if (g.imageUrl && g.imageUrl.trim() && !seen.has(g.imageUrl.trim())) {
          const trimmed = g.imageUrl.trim();
          list.push({
            url: trimmed,
            caption: g.caption || '',
            alt: g.altText || article.title,
          });
          seen.add(trimmed);
        }
      });
    }

    return list;
  }, [article.coverImage, article.galleryImages, article.title]);

  const currentImage = allImages[activeImageIndex] || (allImages.length > 0 ? allImages[0] : null);

  const handlePrev = (e: React.MouseEvent) => {
    e.stopPropagation();
    setImgLoaded(false);
    setActiveImageIndex((prev) => (prev - 1 + allImages.length) % allImages.length);
  };

  const handleNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    setImgLoaded(false);
    setActiveImageIndex((prev) => (prev + 1) % allImages.length);
  };

  const handleSelectThumbnail = (index: number) => {
    if (index === activeImageIndex) return;
    setImgLoaded(false);
    setActiveImageIndex(index);
  };

  const sanitizedContent = article.content
    ? DOMPurify.sanitize(article.content)
    : '';

  return (
    <div style={{ width: '100%' }}>
      {/* 3. Hero Image Gallery Slider: max-width 1100px, aspect-ratio 16/9, border-radius 16px, 32px vertical margin */}
      <div
        style={{
          maxWidth: '1100px',
          width: '100%',
          margin: '32px auto',
          boxSizing: 'border-box',
        }}
      >
        {/* Main Image Container */}
        <div
          style={{
            width: '100%',
            aspectRatio: '16 / 9',
            borderRadius: '16px',
            overflow: 'hidden',
            backgroundColor: 'rgba(214, 197, 179, 0.25)',
            position: 'relative',
            boxShadow: '0 8px 30px rgba(0, 0, 0, 0.08)',
          }}
        >
          {currentImage?.url && !imgError ? (
            <img
              key={currentImage.url}
              src={currentImage.url}
              alt={currentImage.alt || article.title}
              loading="lazy"
              onLoad={() => setImgLoaded(true)}
              onError={() => setImgError(true)}
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                display: 'block',
                opacity: imgLoaded ? 1 : 0,
                transition: 'opacity 300ms ease',
              }}
            />
          ) : (
            <div
              style={{
                width: '100%',
                height: '100%',
                background:
                  'linear-gradient(135deg, rgba(62,88,104,0.18) 0%, rgba(118,137,151,0.12) 50%, rgba(233,221,201,0.45) 100%)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '24px',
                textAlign: 'center',
              }}
            >
              <span
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '2.5rem',
                  fontWeight: 700,
                  color: 'var(--color-slate-blue)',
                  marginBottom: '8px',
                }}
              >
                E-Cell
              </span>
              <span
                style={{
                  fontFamily: 'var(--font-body)',
                  fontSize: '0.8125rem',
                  textTransform: 'uppercase',
                  letterSpacing: '0.14em',
                  color: 'var(--color-text-secondary)',
                  fontWeight: 600,
                }}
              >
                NKOCET Journal Article
              </span>
            </div>
          )}

          {/* Slider Prev & Next Arrow Controls (shown when > 1 image) */}
          {allImages.length > 1 && (
            <>
              {/* Prev Button */}
              <button
                type="button"
                onClick={handlePrev}
                aria-label="Previous image"
                style={{
                  position: 'absolute',
                  left: '16px',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  width: '46px',
                  height: '46px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(15, 23, 42, 0.72)',
                  backdropFilter: 'blur(10px)',
                  border: '1px solid rgba(255, 255, 255, 0.35)',
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  transition: 'all 200ms ease',
                  zIndex: 10,
                  boxShadow: '0 4px 14px rgba(0, 0, 0, 0.35)',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor = 'rgba(15, 23, 42, 0.95)';
                  e.currentTarget.style.transform = 'translateY(-50%) scale(1.08)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = 'rgba(15, 23, 42, 0.72)';
                  e.currentTarget.style.transform = 'translateY(-50%) scale(1)';
                }}
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="15 18 9 12 15 6" />
                </svg>
              </button>

              {/* Next Button */}
              <button
                type="button"
                onClick={handleNext}
                aria-label="Next image"
                style={{
                  position: 'absolute',
                  right: '16px',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  width: '46px',
                  height: '46px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(15, 23, 42, 0.72)',
                  backdropFilter: 'blur(10px)',
                  border: '1px solid rgba(255, 255, 255, 0.35)',
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  transition: 'all 200ms ease',
                  zIndex: 10,
                  boxShadow: '0 4px 14px rgba(0, 0, 0, 0.35)',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor = 'rgba(15, 23, 42, 0.95)';
                  e.currentTarget.style.transform = 'translateY(-50%) scale(1.08)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = 'rgba(15, 23, 42, 0.72)';
                  e.currentTarget.style.transform = 'translateY(-50%) scale(1)';
                }}
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </button>

              {/* Image Counter Badge (e.g. 1 / 6) */}
              <div
                style={{
                  position: 'absolute',
                  top: '16px',
                  right: '16px',
                  padding: '5px 14px',
                  borderRadius: '9999px',
                  backgroundColor: 'rgba(15, 23, 42, 0.75)',
                  backdropFilter: 'blur(8px)',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  fontWeight: 700,
                  fontFamily: 'var(--font-body)',
                  letterSpacing: '0.06em',
                  zIndex: 10,
                  border: '1px solid rgba(255, 255, 255, 0.25)',
                }}
              >
                {activeImageIndex + 1} / {allImages.length}
              </div>
            </>
          )}
        </div>

        {/* Caption for current image if present */}
        {currentImage?.caption && (
          <div
            style={{
              marginTop: '10px',
              fontSize: '13px',
              color: 'var(--color-text-secondary)',
              fontStyle: 'italic',
              fontFamily: 'var(--font-body)',
              textAlign: 'center',
            }}
          >
            {currentImage.caption}
          </div>
        )}

        {/* Below Horizontal Line / Thumbnail Strip for all images */}
        {allImages.length > 1 && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginTop: '16px',
              padding: '6px 4px 12px 4px',
              overflowX: 'auto',
              scrollbarWidth: 'thin',
              boxSizing: 'border-box',
            }}
          >
            {allImages.map((img, idx) => {
              const isActive = idx === activeImageIndex;
              return (
                <button
                  key={`${img.url}-${idx}`}
                  type="button"
                  onClick={() => handleSelectThumbnail(idx)}
                  aria-label={`View photo ${idx + 1}`}
                  style={{
                    flexShrink: 0,
                    width: '92px',
                    height: '60px',
                    borderRadius: '10px',
                    overflow: 'hidden',
                    padding: 0,
                    border: isActive
                      ? '3px solid var(--color-slate-blue, #3E5868)'
                      : '2px solid rgba(214, 197, 179, 0.6)',
                    boxShadow: isActive
                      ? '0 0 0 3px rgba(62, 88, 104, 0.35), 0 4px 10px rgba(0, 0, 0, 0.15)'
                      : 'none',
                    opacity: isActive ? 1 : 0.65,
                    transform: isActive ? 'scale(1.06)' : 'scale(1)',
                    transition: 'all 200ms ease',
                    cursor: 'pointer',
                    backgroundColor: 'rgba(214, 197, 179, 0.35)',
                    position: 'relative',
                  }}
                  onMouseEnter={(e) => {
                    if (!isActive) {
                      e.currentTarget.style.opacity = '0.9';
                      e.currentTarget.style.transform = 'scale(1.03)';
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (!isActive) {
                      e.currentTarget.style.opacity = '0.65';
                      e.currentTarget.style.transform = 'scale(1)';
                    }
                  }}
                >
                  <img
                    src={img.url}
                    alt={img.alt || `Photo ${idx + 1}`}
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      display: 'block',
                    }}
                  />
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Optional "Key Takeaways" box (only rendered if article.keyPoints exists and is not empty) */}
      {article.keyPoints && article.keyPoints.length > 0 && (
        <aside
          aria-label="Key Takeaways"
          style={{
            maxWidth: '720px',
            margin: '0 auto 36px auto',
            padding: '24px',
            borderRadius: '12px',
            backgroundColor: 'rgba(62, 88, 104, 0.05)',
            border: '1px solid rgba(214, 197, 179, 0.6)',
            boxSizing: 'border-box',
          }}
        >
          <div
            style={{
              fontFamily: 'var(--font-body)',
              fontSize: '0.6875rem',
              fontWeight: 700,
              textTransform: 'uppercase',
              letterSpacing: '0.12em',
              color: 'var(--color-slate-blue, #3E5868)',
              marginBottom: '12px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span>💡</span>
            <span>Key Takeaways</span>
          </div>
          <ul
            style={{
              margin: 0,
              paddingLeft: '1.25rem',
              fontFamily: 'var(--font-body)',
              fontSize: '0.9375rem',
              lineHeight: 1.6,
              color: 'var(--color-text-primary)',
              display: 'flex',
              flexDirection: 'column',
              gap: '8px',
            }}
          >
            {article.keyPoints.map((point, idx) => (
              <li key={idx}>{point}</li>
            ))}
          </ul>
        </aside>
      )}

      {/* 4. Body: centered reading column (max-width 720px), Inter 18px, line-height 1.8 */}
      <div
        className="news-article-reading-body"
        style={{
          maxWidth: '720px',
          margin: '0 auto',
          boxSizing: 'border-box',
          width: '100%',
        }}
        dangerouslySetInnerHTML={{ __html: sanitizedContent }}
      />
    </div>
  );
}
